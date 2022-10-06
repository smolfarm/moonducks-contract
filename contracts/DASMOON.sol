/**
 *                          _            _       
 * ._ _ _  ___  ___ ._ _  _| | _ _  ___ | |__ ___
 * | ' ' |/ . \/ . \| ' |/ . || | |/ | '| / /<_-<
 * |_|_|_|\___/\___/|_|_|\___|`___|\_|_.|_\_\/__/
 *
 *           Pixel Art Dastardly Ducks
 *             project by: smol farm
 *             contract by: ens0.eth
 */
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

error MaxQuantityExceeded();
error InsufficientEther();
error ExceedsMaximumSupply();
error PromoAlreadyRun();
error FreeMintAlreadyClaimed();
error InvalidProof();
error PromoNotRun();

contract DastardlyMoonducks is ERC721A, Ownable {
    uint256 public constant MINT_PRICE = 0.005 ether;
    uint16 public constant MAX_DUCKS = 2500;
    string public constant BASE_URI = "ipfs://QmciDVqD2iDN4xaVooY4KM3kUPWCDxCSY2cAV5EnhuvYGh/";

    bytes32 public freeMintMerkleRoot = 0x25c15ba4c412e8944a2a70307fd924fbafc09205c0ae141097aed68aa0cfaef4;
    uint16 public freeDucksRemaining = 1142;

    // Track whether an address has claimed a free duck
    mapping(address => bool) public freeMintClaimed;

    constructor() ERC721A("Dastardly Moonducks", "DASMOON") {}

    /**
     * Enable current Dastardly Ducks holders to claim a Moonduck for free
     */
    function freeMint(bytes32[] calldata proof) external {
        if(!MerkleProof.verify(proof, freeMintMerkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();

        unchecked {
            if(totalSupply() == 0) revert PromoNotRun();
            if(freeMintClaimed[msg.sender]) revert FreeMintAlreadyClaimed();
            if(totalSupply() + 1 > MAX_DUCKS) revert ExceedsMaximumSupply();

            --freeDucksRemaining;
            freeMintClaimed[msg.sender] = true;
        }

        _mint(msg.sender, 1);
    }

    /**
     * Public sale for Moonducks not distributed through promoMint() or freeMint()
     */
    function paidMint(uint8 qty) external payable {
        if(qty > 100) revert MaxQuantityExceeded();

        unchecked {
            if(totalSupply() == 0) revert PromoNotRun();
            if(msg.value < qty * MINT_PRICE) revert InsufficientEther();

            // Ensure we don't go over supply, leaving room for free ducks to be claimed
            if(totalSupply() + qty + freeDucksRemaining > MAX_DUCKS) revert ExceedsMaximumSupply();
        }

        _mint(msg.sender, qty);
    }

    /**
     * Mint the first 40 moonducks to smol farm-held wallets
     */
    function promoMint() external onlyOwner {
        if(totalSupply() > 0) revert PromoAlreadyRun();

        _mint(0x8aa986eB2F0D3b5001C9C2093698A4e13d646D5b, 10);
        _mint(0x8f4612e9aAB90eaD61A1637436BCb9FD0b606652, 10);
        _mint(0x72CAa8687E5C63f8bA2a271212556dA5eD58f0b0, 20);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    /**
     * Set the Merkle root for the free mints
     */
    function setFreeMintMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        freeMintMerkleRoot = newMerkleRoot;
    }

    /**
     * Sets the number of claimable free ducks. Can be zeroed out to enable minting of rest of collection after 
     * claim period for free moonducks ends.
     */
    function setFreeDucksRemaining(uint16 newFreeDucksRemaining) external onlyOwner {
        freeDucksRemaining = newFreeDucksRemaining;
    }
}
