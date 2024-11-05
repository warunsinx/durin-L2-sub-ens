// ***********************************************
// ▗▖  ▗▖ ▗▄▖ ▗▖  ▗▖▗▄▄▄▖ ▗▄▄▖▗▄▄▄▖▗▄▖ ▗▖  ▗▖▗▄▄▄▖
// ▐▛▚▖▐▌▐▌ ▐▌▐▛▚▞▜▌▐▌   ▐▌     █ ▐▌ ▐▌▐▛▚▖▐▌▐▌
// ▐▌ ▝▜▌▐▛▀▜▌▐▌  ▐▌▐▛▀▀▘ ▝▀▚▖  █ ▐▌ ▐▌▐▌ ▝▜▌▐▛▀▀▘
// ▐▌  ▐▌▐▌ ▐▌▐▌  ▐▌▐▙▄▄▖▗▄▄▞▘  █ ▝▚▄▞▘▐▌  ▐▌▐▙▄▄▖
// ***********************************************

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @author darianb.eth + Unruggable
/// @custom:project Durin
/// @custom:company NameStone

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Registry/Resolver All-in-one (for Layer 2)
/// @dev The resolution functions works with standard selectors, switching out node for labelhash
contract L2Registry is ERC721, AccessControl {
    function supportsInterface(
        bytes4 x
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(x);
    }

    // ownership logic
    modifier onlyTokenOperator(bytes32 labelhash) {
        address owner = _ownerOf(uint256(labelhash));
        if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    // Errors
    error Unauthorized();

    // Events
    event Registered(string label, address owner);
    event TextChanged(bytes32 indexed labelhash, string key, string value);
    event AddrChanged(bytes32 indexed labelhash, uint256 coinType, bytes value);
    event ContenthashChanged(bytes32 indexed labelhash, bytes value);

    // Structs to prevent stack too deep errors with multirecord updates
    struct Text {
        string key;
        string value;
    }
    struct Addr {
        uint256 coinType;
        bytes value;
    }

    // AccessControl roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    // Constants
    uint256 constant COIN_TYPE_ETH = 60;

    // Properties
    uint256 public totalSupply;
    string public baseUri;
    mapping(bytes32 labelhash => mapping(string key => string)) _texts;
    mapping(bytes32 labelhash => mapping(uint256 coinType => bytes)) _addrs;
    mapping(bytes32 labelhash => bytes) _chashes;
    mapping(bytes32 labelhash => string) _labels;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) ERC721(_name, _symbol) {
        baseUri = _baseUri;

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Adds a registrar with the specified address.
     * Only a address with the ADMIN_ROLE can call this function.
     *
     * @param registrar The address of the registrar to be added.
     */
    function addRegistrar(address registrar) external onlyRole(ADMIN_ROLE) {
        _grantRole(REGISTRAR_ROLE, registrar);
    }

    /**
     * @dev Removes a registrar from the L2Registry contract.
     * Only a `address with the ADMIN_ROLE can call this function.
     *
     * @param registrar The address of the registrar to be removed.
     */
    function removeRegistrar(address registrar) external onlyRole(ADMIN_ROLE) {
        _revokeRole(REGISTRAR_ROLE, registrar);
    }

    function register(
        string calldata label,
        address owner
    ) external onlyRole(REGISTRAR_ROLE) {
        bytes32 labelhash = keccak256(abi.encodePacked(label));
        uint256 tokenId = uint256(labelhash);
        // This will fail if the node is already registered
        _safeMint(owner, tokenId);
        _labels[labelhash] = label;
        totalSupply++;
        emit Registered(label, owner);
    }

    //
    // Getters
    //

    // Record level
    function addr(bytes32 labelhash) public view returns (address) {
        return address(uint160(bytes20(addr(labelhash, COIN_TYPE_ETH))));
    }

    function addr(
        bytes32 labelhash,
        uint256 cointype
    ) public view returns (bytes memory) {
        return _addrs[labelhash][cointype];
    }

    function text(
        bytes32 labelhash,
        string calldata key
    ) external view returns (string memory) {
        return _texts[labelhash][key];
    }

    function contenthash(
        bytes32 labelhash
    ) external view returns (bytes memory) {
        return _chashes[labelhash];
    }

    // Utils to get a label from its labelhash
    function labelFor(bytes32 labelhash) external view returns (string memory) {
        return _labels[labelhash];
    }

    //
    // Setters
    //

    // Contract level
    function setBaseURI(string memory _baseUri) external onlyRole(ADMIN_ROLE) {
        baseUri = _baseUri;
    }

    // Record level
    // Internal setters
    function setAddr(
        bytes32 labelhash,
        uint256 coinType,
        bytes memory value
    ) public {
        _addrs[labelhash][coinType] = value;
        emit AddrChanged(labelhash, coinType, value);
    }

    function setText(
        bytes32 labelhash,
        string memory key,
        string memory value
    ) public {
        _texts[labelhash][key] = value;
        emit TextChanged(labelhash, key, value);
    }

    function setContenthash(bytes32 labelhash, bytes memory value) public {
        _chashes[labelhash] = value;
        emit ContenthashChanged(labelhash, value);
    }

    // Convenient multicall to set records
    function setRecords(
        bytes32 labelhash,
        Text[] calldata texts,
        Addr[] calldata addrs,
        bytes calldata chash
    ) external onlyTokenOperator(labelhash) {
        uint256 i;

        // Set texts
        for (i = 0; i < texts.length; i++) {
            setText(labelhash, texts[i].key, texts[i].value);
        }

        // Set addresses
        for (i = 0; i < addrs.length; i++) {
            setAddr(labelhash, addrs[i].coinType, addrs[i].value);
        }

        // Set content hash if provided (non-empty)
        if (chash.length > 0) {
            setContenthash(labelhash, chash);
        }
    }
}
