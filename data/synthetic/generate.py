"""Kalambatan synthetic telecom dataset generator.

Generates a realistic Philippine telecom dataset with churn drivers
deliberately embedded so downstream ML (Phase 3) finds real signal:

  - contract expiration         -> churn hazard spike
  - support ticket frequency    -> hazard increase
  - declining data usage        -> hazard increase
  - late / missed payments      -> hazard increase (+ involuntary churn)
  - accepted retention offers   -> hazard decrease

Outputs 7 CSVs (the Bronze layer) into data/synthetic/output/.

Usage:
    python generate.py [--customers 5000] [--months 24] [--seed 42]

Zero-cost: numpy + pandas only.
"""

import argparse
from datetime import date
from pathlib import Path

import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# Reference data (Philippine telecom flavor)
# ---------------------------------------------------------------------------

PLANS = [
    # plan_id, name, type, fee_php, data_gb, voice_min, sms, contract_months
    ("PLN-001", "SakayLite Prepaid", "prepaid", 199, 3, 100, 100, 0),
    ("PLN-002", "SakaySurf Prepaid", "prepaid", 299, 8, 150, 200, 0),
    ("PLN-003", "SakayMax Prepaid", "prepaid", 499, 16, 300, 500, 0),
    ("PLN-004", "Kable Postpaid 599", "postpaid", 599, 10, 500, 500, 12),
    ("PLN-005", "Kable Postpaid 999", "postpaid", 999, 25, 1000, 1000, 12),
    ("PLN-006", "Kable Postpaid 1499", "postpaid", 1499, 50, 2000, 1000, 24),
    ("PLN-007", "Kable Unli 1999", "postpaid", 1999, 100, 99999, 99999, 24),
    ("PLN-008", "Kable Unli Pro 2499", "postpaid", 2499, 200, 99999, 99999, 24),
]

REGIONS = {
    "NCR": ["Quezon City", "Manila", "Makati", "Taguig", "Pasig"],
    "CALABARZON": ["Imus", "Dasmarinas", "Antipolo", "Calamba", "Lipa"],
    "Central Luzon": ["Angeles", "San Fernando", "Olongapo", "Malolos"],
    "Central Visayas": ["Cebu City", "Mandaue", "Lapu-Lapu", "Talisay"],
    "Davao Region": ["Davao City", "Tagum", "Digos", "Panabo"],
    "Western Visayas": ["Iloilo City", "Bacolod", "Roxas"],
}
REGION_WEIGHTS = [0.30, 0.20, 0.14, 0.14, 0.12, 0.10]

DEVICE_BRANDS = ["Samsung", "Xiaomi", "Oppo", "Vivo", "Apple", "Realme", "Infinix"]
DEVICE_TIERS = {"Apple": "premium", "Samsung": "mid", "Xiaomi": "budget",
                "Oppo": "mid", "Vivo": "mid", "Realme": "budget", "Infinix": "budget"}
CHANNELS = ["retail_store", "online", "telesales", "dealer", "app"]
TICKET_CATEGORIES = ["network_quality", "billing_dispute", "service_request", "account_issue"]
RETENTION_TYPES = [
    ("discount_offer", 0.40), ("plan_upgrade", 0.25),
    ("loyalty_reward", 0.20), ("winback_call", 0.15),
]


def month_seq(start: date, n: int) -> list[date]:
    out, y, m = [], start.year, start.month
    for _ in range(n):
        out.append(date(y, m, 1))
        m += 1
        if m == 13:
            y, m = y + 1, 1
    return out


def generate(n_customers: int, n_months: int, seed: int, out_dir: Path) -> None:
    rng = np.random.default_rng(seed)
    months = month_seq(date(2024, 1, 1), n_months)
    plans = pd.DataFrame(PLANS, columns=[
        "plan_id", "plan_name", "plan_type", "monthly_fee_php",
        "data_allowance_gb", "voice_minutes", "sms_allowance", "contract_months"])
    plans["launch_date"] = "2022-01-01"

    # ----- customers -------------------------------------------------------
    n0 = n_customers
    region_idx = rng.choice(len(REGIONS), n0, p=REGION_WEIGHTS)
    regions = np.array(list(REGIONS.keys()))[region_idx]
    cities = np.array([rng.choice(REGIONS[r]) for r in regions])
    age = np.clip(rng.normal(36, 12, n0).astype(int), 18, 75)
    # plan choice loosely correlated with age (older -> postpaid) and randomness
    postpaid_p = np.clip(0.25 + (age - 18) / 120, 0.2, 0.7)
    is_postpaid = rng.random(n0) < postpaid_p
    plan_ids = np.where(
        is_postpaid,
        rng.choice(plans.loc[plans.plan_type == "postpaid", "plan_id"], n0),
        rng.choice(plans.loc[plans.plan_type == "prepaid", "plan_id"], n0),
    )
    # signup: 70% before window (tenure up to 6y), 30% spread inside window
    pre = rng.random(n0) < 0.70
    signup_offset_months = np.where(
        pre, -rng.integers(1, 72, n0), rng.integers(0, n_months, n0))
    signup_month_idx = signup_offset_months  # relative to months[0]
    brands = rng.choice(DEVICE_BRANDS, n0, p=[0.24, 0.20, 0.14, 0.13, 0.10, 0.11, 0.08])

    plan_lookup = plans.set_index("plan_id")
    fee = plan_lookup.loc[plan_ids, "monthly_fee_php"].to_numpy().astype(float)
    allowance = plan_lookup.loc[plan_ids, "data_allowance_gb"].to_numpy().astype(float)
    contract_len = plan_lookup.loc[plan_ids, "contract_months"].to_numpy()

    customers = pd.DataFrame({
        "customer_id": [f"CUST-{i:06d}" for i in range(1, n0 + 1)],
        "age": age,
        "gender": rng.choice(["F", "M"], n0),
        "region": regions,
        "city": cities,
        "plan_id": plan_ids,
        "device_brand": brands,
        "device_tier": [DEVICE_TIERS[b] for b in brands],
        "acquisition_channel": rng.choice(CHANNELS, n0, p=[0.32, 0.26, 0.12, 0.18, 0.12]),
        "autopay_enrolled": (rng.random(n0) < np.where(is_postpaid, 0.45, 0.10)),
        "email_opt_in": rng.random(n0) < 0.6,
    })
    signup_dates = []
    for off in signup_month_idx:
        base = months[0]
        y, m = base.year, base.month + int(off)
        y += (m - 1) // 12
        m = (m - 1) % 12 + 1
        signup_dates.append(date(y, m, min(int(rng.integers(1, 28)), 28)))
    customers["signup_date"] = signup_dates
    customers["contract_start_date"] = np.where(contract_len > 0, customers["signup_date"], None)
    customers["contract_end_date"] = [
        None if cl == 0 else date(
            sd.year + (sd.month - 1 + int(cl)) // 12,
            (sd.month - 1 + int(cl)) % 12 + 1, 1)
        for sd, cl in zip(customers["signup_date"], contract_len)
    ]

    # ----- per-customer latent behavior ------------------------------------
    usage_base = np.clip(rng.lognormal(0, 0.5, n0), 0.2, 3.0) * np.clip(allowance, 2, 60) * 0.7
    decline_trend = rng.random(n0) < 0.18          # silently disengaging users
    price_sensitivity = rng.beta(2, 5, n0)         # 0..1
    ticket_rate = rng.gamma(1.4, 0.08, n0)         # expected tickets / month
    monthly_decline = np.where(decline_trend, rng.uniform(0.04, 0.12, n0), 0.0)

    # ----- simulation state -------------------------------------------------
    active = np.array([off <= 0 for off in signup_month_idx])  # active at window start
    churned = np.zeros(n0, dtype=bool)
    unpaid_streak = np.zeros(n0, dtype=int)
    late_recent = np.zeros(n0, dtype=float)
    tickets_recent = np.zeros(n0, dtype=float)
    retention_shield = np.zeros(n0, dtype=int)     # months of reduced hazard
    usage_level = usage_base.copy()

    billing, usage_rows, tickets, retention, churn_events = [], [], [], [], []
    inv_n = tkt_n = act_n = chn_n = 0

    for mi, mo in enumerate(months):
        # activate customers signing up this month
        joining = (signup_month_idx == mi) & ~active & ~churned
        active |= joining
        live = np.where(active & ~churned)[0]
        if len(live) == 0:
            continue

        tenure = mi - signup_month_idx  # months since signup (>=0 for live)

        # ---- usage ----
        seasonal = 1.0 + 0.06 * np.sin(2 * np.pi * (mo.month / 12.0))
        usage_level[live] *= (1 - monthly_decline[live])
        used = np.maximum(usage_level[live] * seasonal * rng.normal(1, 0.18, len(live)), 0.05)
        voice = np.maximum(rng.normal(180, 90, len(live)) * (1 - 0.5 * monthly_decline[live] * tenure[live].clip(0, 12) / 12), 0)
        for j, ci in enumerate(live):
            usage_rows.append((
                f"USG-{mi:02d}-{ci:06d}", customers.customer_id[ci], mo,
                round(float(used[j]), 2), int(voice[j]), int(rng.poisson(40)),
                round(float(np.clip(rng.normal(28, 9), 2, 80)), 1),
                round(float(np.clip(rng.gamma(2, 0.004), 0, 0.08)), 4),
            ))

        # ---- billing ----
        overage = np.maximum(used - allowance[live], 0) * 12.0  # ₱12 / GB over
        total = fee[live] + overage
        pay_late_p = 0.06 + 0.10 * price_sensitivity[live] - 0.04 * customers.autopay_enrolled.to_numpy()[live]
        r = rng.random(len(live))
        status = np.where(r < pay_late_p, "late", "paid")
        status = np.where(r < pay_late_p * 0.35, "unpaid", status)
        for j, ci in enumerate(live):
            inv_n += 1
            billing.append((
                f"INV-{inv_n:07d}", customers.customer_id[ci], mo,
                round(float(fee[live][j]), 2), round(float(overage[j]), 2),
                round(float(total[j]), 2), status[j],
                None if status[j] == "unpaid" else date(mo.year, mo.month, int(rng.integers(1, 28))),
            ))
        unpaid_streak[live] = np.where(status == "unpaid", unpaid_streak[live] + 1, 0)
        late_recent[live] = late_recent[live] * 0.6 + (status != "paid").astype(float)

        # ---- support tickets ----
        n_tix = rng.poisson(ticket_rate[live] * (1 + 1.5 * monthly_decline[live] * 5))
        for j, ci in enumerate(live):
            for _ in range(int(n_tix[j])):
                tkt_n += 1
                opened = date(mo.year, mo.month, int(rng.integers(1, 28)))
                cat = TICKET_CATEGORIES[int(rng.choice(4, p=[0.38, 0.27, 0.20, 0.15]))]
                resolved_in = int(rng.integers(0, 9))
                tickets.append((
                    f"TKT-{tkt_n:07d}", customers.customer_id[ci], opened,
                    rng.choice(["hotline", "app", "store", "social"]), cat,
                    rng.choice(["low", "medium", "high"], p=[0.5, 0.35, 0.15]),
                    opened + pd.Timedelta(days=resolved_in),
                    int(rng.integers(1, 6)) if rng.random() < 0.7 else None,
                ))
        tickets_recent[live] = tickets_recent[live] * 0.5 + n_tix

        # ---- churn hazard ----
        ce = customers.contract_end_date.to_numpy()
        contract_ending = np.array([
            ce[ci] is not None and abs((ce[ci].year - mo.year) * 12 + ce[ci].month - mo.month) <= 1
            for ci in live])
        usage_ratio = usage_level[live] / np.maximum(usage_base[live], 0.1)
        hazard = (
            0.010
            + 0.045 * contract_ending
            + 0.016 * np.clip(tickets_recent[live], 0, 4)
            + 0.040 * (usage_ratio < 0.7)
            + 0.022 * np.clip(late_recent[live], 0, 3)
            + 0.030 * price_sensitivity[live] * (fee[live] / 2499)
            - 0.004 * np.clip(tenure[live], 0, 36) / 12
        )
        hazard = np.where(retention_shield[live] > 0, hazard * 0.45, hazard)
        hazard = np.clip(hazard, 0.002, 0.45)

        # ---- retention targeting (company acts on risky customers) ----
        risky = hazard > 0.07
        targeted = risky & (rng.random(len(live)) < 0.40)
        for j, ci in enumerate(live):
            if targeted[j]:
                act_n += 1
                at_i = int(rng.choice(4, p=[w for _, w in RETENTION_TYPES]))
                accepted = bool(rng.random() < 0.35)
                retention.append((
                    f"ACT-{act_n:06d}", customers.customer_id[ci],
                    date(mo.year, mo.month, int(rng.integers(1, 28))),
                    f"RETAIN-{mo.strftime('%Y%m')}", RETENTION_TYPES[at_i][0],
                    round(float(rng.choice([100, 200, 300, 500])), 2), accepted,
                ))
                if accepted:
                    retention_shield[ci] = 3
                    hazard[j] *= 0.45
        retention_shield[live] = np.maximum(retention_shield[live] - 1, 0)

        # ---- churn events ----
        involuntary = unpaid_streak[live] >= 2
        churn_now = involuntary | (rng.random(len(live)) < hazard)
        for j, ci in enumerate(live):
            if not churn_now[j]:
                continue
            chn_n += 1
            if involuntary[j]:
                ctype, reason = "involuntary", "non_payment"
            else:
                drivers = {
                    "contract_expired": 0.045 * contract_ending[j],
                    "poor_service_experience": 0.016 * min(tickets_recent[ci], 4),
                    "reduced_engagement": 0.040 * (usage_ratio[j] < 0.7),
                    "price_dissatisfaction": 0.030 * price_sensitivity[ci] * (fee[ci] / 2499),
                }
                reason = max(drivers, key=drivers.get)
                if max(drivers.values()) < 0.012:
                    reason = "competitor_switch"
                ctype = "voluntary"
            churn_events.append((
                f"CHN-{chn_n:06d}", customers.customer_id[ci],
                date(mo.year, mo.month, int(rng.integers(2, 28))), mo,
                ctype, reason, customers.plan_id[ci], int(tenure[ci]),
            ))
            churned[ci] = True
            active[ci] = False

    # ----- write CSVs -------------------------------------------------------
    out_dir.mkdir(parents=True, exist_ok=True)
    customers.to_csv(out_dir / "raw_customers.csv", index=False)
    plans.to_csv(out_dir / "raw_plans.csv", index=False)
    pd.DataFrame(billing, columns=[
        "invoice_id", "customer_id", "billing_month", "plan_fee_php", "overage_php",
        "total_amount_php", "payment_status", "paid_date",
    ]).to_csv(out_dir / "raw_billing.csv", index=False)
    pd.DataFrame(usage_rows, columns=[
        "usage_id", "customer_id", "usage_month", "data_used_gb", "voice_minutes_used",
        "sms_sent", "avg_download_mbps", "dropped_call_rate",
    ]).to_csv(out_dir / "raw_network_usage.csv", index=False)
    pd.DataFrame(tickets, columns=[
        "ticket_id", "customer_id", "opened_date", "channel", "category",
        "priority", "resolved_date", "csat_score",
    ]).to_csv(out_dir / "raw_support_tickets.csv", index=False)
    pd.DataFrame(retention, columns=[
        "action_id", "customer_id", "action_date", "campaign_name", "action_type",
        "offer_value_php", "accepted",
    ]).to_csv(out_dir / "raw_retention_actions.csv", index=False)
    pd.DataFrame(churn_events, columns=[
        "churn_id", "customer_id", "churn_date", "churn_month", "churn_type",
        "churn_reason", "last_plan_id", "tenure_months_at_churn",
    ]).to_csv(out_dir / "raw_churn_events.csv", index=False)

    print(f"customers={n0}  invoices={inv_n}  usage_rows={len(usage_rows)}")
    print(f"tickets={tkt_n}  retention_actions={act_n}  churn_events={chn_n}")
    print(f"overall churn = {chn_n / n0:.1%} of base over {n_months} months")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--customers", type=int, default=5000)
    ap.add_argument("--months", type=int, default=24)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--out", type=Path, default=Path(__file__).parent / "output")
    args = ap.parse_args()
    generate(args.customers, args.months, args.seed, args.out)
