//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspector;
    
    

    // modifier onlyBuyer => verify for "Only buyer call this method"
    modifier onlyBuyer(uint256 _nftId){
        require(msg.sender == buyerList[_nftId], "Only buyer call this method");
        _;
    }
    // modifier onlySeller => verify for "Only seller call this method"
    modifier onlySeller{
        require(msg.sender == seller, "Only seller call this method");
        _;
    }
    // modifier onlyInspector => verify for "Only inspector call this method"
    modifier onlyInspector{
        require(msg.sender == inspector, "Only inspector call this method");
        _;
    }
    //mappings *isListed**purchuasePrice**escrowAmount**buyer**inspectionPassed*
    mapping(uint256 => bool) public isListed;
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public escrowAmount;
    mapping(uint256 => address) public buyerList;
    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => bool) public inspectionStatus;
    mapping(uint256 => mapping(address => bool)) public approval;

    constructor(
        address _nftAddress,
        address payable _seller,
        address _inspector
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
    }

    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // Transfer NFT from seller to this contract
        address _owner = IERC721(nftAddress).ownerOf(_nftID);
        IERC721(nftAddress).transferFrom(_owner, address(this), _nftID);
        isListed[_nftID] = true;
        itemPrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyerList[_nftID] = _buyer;
    }
            // Put Under Contract (only buyer - payable escrow)   
    function depositEarnest(uint256 _nftId) public payable onlyBuyer(_nftId){
        require(msg.value >= escrowAmount[_nftId]);
        escrowAmount[_nftId] = msg.value;
    }


    // Update Inspection Status (only inspector)
    function updateInspectionStatus(uint256 _nftId, bool _status) public onlyInspector{
        inspectionPassed[_nftId] = _status;
    } 
    

    // Approve Sale
    function approveSale(uint256 _nftId) public {
        inspectionPassed[_nftId] = true;
        approval[_nftId][msg.sender] = true;
    }

    // Finalize Sale
    // -> Require inspection status 
    // -> Require sale to be authorized
    // -> Require funds to be correct amount
    // -> Transfer NFT to buyer
    // -> Transfer Funds to Seller
    function finalizeSale(uint256 _nftId) public {
        require(inspectionPassed[_nftId] = true, "Approve test failed");
        require(approval[_nftId][buyerList[_nftId]] == true, "The buyer is not approved");
        require(approval[_nftId][seller] == true, "The seller is not approved");
        require(escrowAmount[_nftId] >= itemPrice[_nftId], "Wrong amount on ethers");

        isListed[_nftId] = false;

        IERC721(nftAddress).transferFrom(address(this), buyerList[_nftId], _nftId);
        escrowAmount[_nftId] = 0;
        seller.transfer(getBalance());
    }
        
    // Cancel Sale (handle earnest deposit)
    // -> if inspection status is not approved, then refund, otherwise send to seller
    function cancelSale(uint256 _nftId) public payable {
        if(!inspectionPassed[_nftId]){
           payable(buyerList[_nftId]).transfer(address(this).balance); 
        }else{
            payable(seller).transfer(address(this).balance);
        }
    }

    //implement a special receive function in order to receive funds and increase the balance
    receive() external payable {}

            //function getBalance to check the current balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}