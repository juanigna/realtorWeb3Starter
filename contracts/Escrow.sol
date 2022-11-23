//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspector;
    address public buyer;
    

    // modifier onlyBuyer => verify for "Only buyer call this method"
    modifier onlyBuyer{
        require(msg.sender == buyer, "Only buyer call this method");
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
        address _inspector,
        address _buyer
        
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        buyer = _buyer;
        
    }

    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // Transfer NFT from seller to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);

        isListed[_nftID] = true;
        itemPrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyerList[_nftID] = _buyer;
    }
            // Put Under Contract (only buyer - payable escrow)   
    function depositEarnest(uint256 _nftId) public payable onlyBuyer{
        require(msg.value >= escrowAmount[_nftId]);
        payable(address(this)).transfer(escrowAmount[_nftId]); //PREGUNTAR SI VA
    }


    // Update Inspection Status (only inspector)
    function updateInspectionStatus(uint256 _nftId, bool _status) public onlyInspector{
        inspectionStatus[_nftId] = _status;
    } 
    

    // Approve Sale
    function approveSale(uint256 _nftId) public {
        require(inspectionStatus[_nftId] == true, "Inspection status is off");
        inspectionPassed[_nftId] = true;
        approval[_nftId][msg.sender] = true;
    }

    // Finalize Sale
    // -> Require inspection status 
    // -> Require sale to be authorized
    // -> Require funds to be correct amount
    // -> Transfer NFT to buyer
    // -> Transfer Funds to Seller
    function finalizeSale(uint256 _nftId) public payable{
        require(inspectionPassed[_nftId] = true, "Approve test failed");
        require(msg.value >= escrowAmount[_nftId], "Wrong amount on ethers");
        IERC721(nftAddress).transferFrom(seller, buyer, _nftId);
        seller.transfer(escrowAmount[_nftId]);
        escrowAmount[_nftId] = 0;
    } //complete
        
    // Cancel Sale (handle earnest deposit)
    // -> if inspection status is not approved, then refund, otherwise send to seller
    function cancelSale() public {

    }

    //implement a special receive function in order to receive funds and increase the balance
    receive() external payable {}

            //function getBalance to check the current balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}