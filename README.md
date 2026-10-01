# Mandi-Go — Flutter App (Phase 1 scaffold)

This is the Grower-side app scaffold: login, dashboard, Buy Inputs, Orders, Profile —
matching the reference design, running on mock data for now.

## How to run this on your machine (Windows)

1. Make sure `flutter doctor` shows no red errors (you should already have Flutter +
   Android Studio installed from the earlier setup step).

2. Create a fresh Flutter project shell (this generates the `android/`, `ios/` folders
   and platform boilerplate that isn't included in this zip):

   ```
   flutter create mandi_go
   ```

3. Copy the files from this zip **into** that new `mandi_go` folder, overwriting the
   `lib/main.dart` and `pubspec.yaml` it generated — i.e. your final folder should have:
   ```
   mandi_go/
     android/         <- from flutter create
     ios/              <- from flutter create
     lib/               <- from this zip (overwrite)
     pubspec.yaml     <- from this zip (overwrite)
   ```

4. Install dependencies:
   ```
   cd mandi_go
   flutter pub get
   ```

5. Plug in your phone (USB debugging on) or start an emulator from Android Studio, then:
   ```
   flutter run
   ```

## What's included right now

**Login → Role Select** — pick Grower or Seller (a real account will support both later)

**Grower side:**
- Dashboard (Home) — stats, market prices, quick "Buy Quality Inputs" preview
- Buy Inputs — full listing with category filter + Buy Now bottom sheet
- My Orders — order history with status badges
- Messages — chat thread list (UI only)
- Wallet — balance, add money/withdraw buttons, transaction history
- Market Prices — full price list
- My Farm — farm profile details
- Profile — "Get Verified" prompt + settings menu

**Seller side:**
- Dashboard — stats + recent orders
- My Listings — manage input products, "Add Listing" form (UI only)
- Orders — incoming orders from Growers, confirm action
- Store Profile — business info + settings menu

All screens run on mock data from `lib/data/mock_data.dart` — no backend calls yet.

## What still needs to be wired to a real backend

- **Auth** — phone OTP login (currently just navigates through)
- **Products/Listings** — Sellers' input products, stored and queried live
- **Orders** — placing an order, status updates flowing between Grower ↔ Seller
- **Wallet** — real balance, add money (payment gateway), transaction history
- **Messages** — real-time chat between Grower and Seller
- **Market Prices** — live price feed (manual admin entry or external data source)
- **Verification** — "Get Verified" approval workflow
- **Images** — product photos, farm photos (needs file storage)
- **Notifications** — order updates, new messages, price alerts
- Phase 2: produce listings by Growers + bidding system for Buyers/Traders
