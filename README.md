# anon_chat_ui

**Anonymous Chat Basecamp QML UI Module** for decentralized private group chat with cryptographic moderation on **Logos Basecamp**.

## Architectural Overview

`el_anon_chat_ui` connects to the `el_anon_chat_core` backend module and provides four integrated views:

1. **Identity View (`IdentityBanner.qml`)**:
   - Generates or imports Nullifier Secret Key (NSK).
   - Computes public identity commitment.
   - Registers and resolves usernames without linking to real on-chain wallets.
   - Monitors revocation and blacklist status.

2. **Rooms View (`RoomList.qml`)**:
   - Room directory browser with threshold configuration (N-of-M).
   - Create new chat rooms with deterministic room ID derivation.
   - Join room with cryptographically signed consent.

3. **Chat View (`ChatView.qml` & `MessageComposer.qml`)**:
   - End-to-end encrypted messaging view.
   - Posts are automatically split via two-tier Shamir Secret Sharing (SSS).
   - Per-post secret shares are ECDH-encrypted to designated room moderators.

4. **Moderation View (`StrikeModal.qml`)**:
   - Review flagged messages and inspect cryptographic tracing tags.
   - Issue multi-signature moderator strikes with evidence hashes.
   - Execute Lagrange polynomial reconstruction to slash and de-anonymize repeated offenders (>= K strikes).

## Directory Structure

```
el_anon_chat_ui/
├── metadata.json           # Basecamp UI module manifest
├── flake.nix               # Nix packaging definition
├── README.md               # User guide & architecture documentation
└── qml/
    ├── Main.qml            # Primary Basecamp window & navigation controller
    ├── components/
    │   ├── IdentityBanner.qml    # Identity & commitment overview
    │   ├── RoomList.qml          # Room browser & join/create actions
    │   ├── ChatView.qml          # Message feed & tracing tag viewer
    │   ├── MessageComposer.qml   # Two-tier SSS encrypted message composer
    │   └── StrikeModal.qml       # Moderator strike & slashing panel
    └── views/
        ├── IdentityView.qml      # Full identity management page
        ├── ChatRoomView.qml      # Active chat room conversation page
        └── ModerationView.qml    # Moderator dashboard & Lagrange aggregator
```

## Build Instructions

Using Nix with Logos Module Builder:
```bash
nix build .#
```
