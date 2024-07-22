# Unify

⚠️ Currently in very early stages, likely to change significantly in the future. It is pre-alpha and not been tested by anyone but myself.

A [BIP78 over Nostr Payjoin](https://github.com/Kukks/BTCPayServer.BIP78/tree/nostr/BTCPayServer.BIP78.Nostr) wallet.

## Config
- Upon first launch RPC and Nostr credentials are automatically created for you (you can edit them, `rpcauth` will automatically update).
- Export the `rpcauth` (from Config) to your `bitcoin.conf`.
- Select the appropriate `rpcport` (8332 for mainnet, 18332 testnet, 38332 signet, 18443 regtest).
- Restart your node.
- Select the `rpcwallet` you'd like to use.
- Add a BIP39 mnemonic (its a hot wallet for now).

## Receive
- Granted your node credentials are correct click "Receive".
- An rpc command is sent to your node to automatically generate a new address from the specified `rpcwallet` or enter any address (BIP84).
- Export the QR/text format of the Payjoin invoice to the sender.
- Once the sender receives your invoice they will add their input and sign the transaction, the signed psbt is then sent to you.
- Once Unify receives the signed psbt from the sender it will display the (mandatory) option to add an input and output in the Receive flow.
- After adding an additional input and output Unify will sign the additional inputs, finalize the psbt, encrypt it and send it back to the Sender via Nostr.
- Once the Sender recieves the "Payjoin proposal" a series of checks is made on the Sender side, the psbt is finalized, a complete raw transaction is created with the option to export or broadcast it.

## Send
- Click "Send".
- Scan/paste an invoice.
- Select an input(s) to pay the invoice with or opt for automatic selction.
- Tap "Payjoin this utxo" to pay the invoice with the selected utxo.
- Unify then builds and signs a psbt, encrypts it and sends it to the recipient via nostr.
- The recipient will do its thing and when complete will send the "Payjoin proposal" to the sender.
- Upon recipt of the "Payjoin proposal" the UI will update and carry out a series of checks on the psbt to ensure we are not being duped into signing a transaction we shouldn't be.
- If all checks pass you will see the raw transaction in hex format with an export or broadcast button enabled.
- Tap broadcast to send the transaction.


## Limitations
- Native segwit inputs and outputs only.
- Must have a BIP39 signer that can sign for your inputs. 
- Tor is not currently used for nostr traffic, a VPN is recommended, your messages will not be identifiable as bitcoin transactions to the relay.

## Wishlist
- NIP44? (currently utilizes NIP4 for cross compatibility).
- Manual change address selection (currently Bitcoin Core will automatically add a change output if needed).
- A "PSBT" tab, where the user can create a psbt by adding inputs/outputs as they wish or by uploading a PSBT.
- More fine grained settings.
- Support different script types, not just BIP84.
- Silent payments.


## TODO
- Watch-only capability, add ability to export each psbt for signing and paste back in.
- Allow sender to add additional inputs/outputs.
- Submit PR to BIP78 nostr addendum to include a `txid` message when either party broadcasts the transaction.







