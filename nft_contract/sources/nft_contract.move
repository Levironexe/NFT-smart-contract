module nft_contract::nft_contract {
use std::string;
    use sui::event;
    use sui::coin::{Self, Coin}; // Add coin import
    use sui::sui::SUI;           // For SUI token

    /// An example NFT that can be minted by anybody
    public struct MYNFT has key, store {
        id: object::UID,
        /// Name for the token
        name: string::String,
        /// Description of the token
        description: string::String,
        /// URL for the token stored as a string
        url: string::String,
    }

    // ===== Events =====

    public struct NFTMinted has copy, drop {
        /// The Object ID of the NFT
        object_id: object::ID,
        /// The creator of the NFT
        creator: address,
        /// The name of the NFT
        name: string::String,
    }

    // ===== Public view functions =====

    /// Get the NFT's `name`
    public fun name(nft: &MYNFT): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &MYNFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url` as a string
    public fun url(nft: &MYNFT): &string::String {
        &nft.url
    }

    // ===== Entrypoints =====

    //function to create a new NFT
    public entry fun mint_with_price(
        payment: &mut Coin<SUI>,    // Payment in SUI
        artist_address: address,
        required_price: u64,        // Price for this specific NFT
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut tx_context::TxContext
    ) {
        // Check if payment is sufficient
        assert!(coin::value(payment) >= required_price, 0); // Error if payment too low

        // Take the payment
        let mut paid_coin = coin::split(payment, required_price, ctx);
        let company_amount = required_price/2;
        let paid_coin_for_company = coin::split(&mut paid_coin, company_amount, ctx);
        let paid_coin_for_artist = paid_coin;

        // Transfer payment to treasury or split between parties
        transfer::public_transfer(paid_coin_for_company, @0xef9e91c776f698bf70dbdd857f79f343e434074567d6beb4c3626c51990ef450);
        transfer::public_transfer(paid_coin_for_artist, artist_address);

        // Create and transfer NFT
        let sender = tx_context::sender(ctx);
        let nft = MYNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: string::utf8(url)
        };

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::transfer(nft, sender)
    }

    //function to split payment between parties
    public fun split_payment(
        mut payment: Coin<SUI>,
        company_share: u64,
        artist_share: u64,
        company_address: address,
        artist_address: address,
        ctx: &mut tx_context::TxContext
    ) {
        let total = coin::value(&payment);
        assert!(company_share + artist_share == total, 0);

        let artist_payment = coin::split(&mut payment, artist_share, ctx);
        transfer::public_transfer(artist_payment, artist_address);
        transfer::public_transfer(payment, company_address);
    }

    /// Custom Transfer `nft` to `recipient`
    public entry fun custom_transfer(
        nft: MYNFT, recipient: address, _: &mut tx_context::TxContext
    ) {
        sui::transfer::public_transfer(nft, recipient);
    }

    /// Update the `description` of `nft` to `new_description`
    public entry fun update_description(
        nft: &mut MYNFT,
        new_description: vector<u8>,
        _: &mut tx_context::TxContext
    ) {
        nft.description = string::utf8(new_description);
    }

    /// Permanently delete `nft`
    public entry fun burn(nft: MYNFT, _: &mut tx_context::TxContext) {
        let MYNFT { id, .. } = nft;
        object::delete(id);
    }
}
