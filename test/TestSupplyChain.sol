pragma solidity >=0.6.0 <0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

// Contract User
contract UserAgent {
    SupplyChain supplyChain;

    constructor(SupplyChain _supplyChain) public payable {
        supplyChain = _supplyChain;
    }

    receive() external payable {}

    function addItem(string memory _name, uint256 _price)
        public
        returns (bool)
    {
        (bool success, ) = address(supplyChain).call(
            abi.encodeWithSignature("addItem(string,uint256)", _name, _price)
        );
        return success;
    }

    function shipItem(uint256 _sku) public returns (bool) {
        (bool success, ) = address(supplyChain).call(
            abi.encodeWithSignature("shipItem(uint256)", _sku)
        );
        return success;
    }

    function buyItem(uint256 _sku, uint256 amount) public returns (bool) {
        (bool success, ) = address(supplyChain).call.value(amount)(
            abi.encodeWithSignature("buyItem(uint256)", _sku)
        );
        return success;
    }

    function receiveItem(uint256 _sku) public returns (bool) {
        (bool success, ) = address(supplyChain).call(
            abi.encodeWithSignature("receiveItem(uint256)", _sku)
        );
        return success;
    }
}

contract TestSupplyChain {
    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    uint256 public initialBalance = 1 ether;
    SupplyChain supplyChain;
    UserAgent seller;
    UserAgent buyer;

    function beforeEach() public {
        supplyChain = new SupplyChain();
        seller = new UserAgent(supplyChain);
        buyer = new UserAgent(supplyChain);

        address(buyer).transfer(1000);

        // Using widget item for all tests
        seller.addItem("car", 100);
    }

    // buyItem

    // test for failure if user does not send enough funds
    function testUserDoesNotSendEnoughFunds() public {
        bool r = buyer.buyItem(0, 50);
        Assert.isFalse(
            r,
            "test for failure if user does not send enough funds"
        );
    }

    // test for purchasing an item that is not for Sale
    function testPurchasedItemIsNotForSale() public {
        bool r = buyer.buyItem(1, 100);
        Assert.isFalse(r, "test for purchasing an item that is not for Sale");
    }

    // shipItem

    // test for calls that are made by not the seller
    function testShipItemNotByTheSeller() public {
        buyer.buyItem(0, 100);
        bool r = buyer.shipItem(0);
        Assert.isFalse(r, "test for calls that are made by not the seller");
    }

    // test for trying to ship an item that is not marked Sold
    function testShipAnItemThatIsNotSold() public {
        bool r = seller.shipItem(0);
        Assert.isFalse(
            r,
            "test for trying to ship an item that is not marked Sold"
        );
    }

    // receiveItem

    // test calling the function from an address that is not the buyer
    function testReceiveItemNotByTheBuyer() public {
        buyer.buyItem(0, 100);
        seller.shipItem(0);
        bool r = seller.receiveItem(0);
        Assert.isFalse(
            r,
            "test calling the function from an address that is not the buyer"
        );
    }

    // test calling the function on an item not marked Shipped
    function testReceiveItemThatIsNotShipped() public {
        buyer.buyItem(0, 100);
        bool r = buyer.receiveItem(0);
        Assert.isFalse(
            r,
            "test calling the function on an item not marked Shipped"
        );
    }
}
