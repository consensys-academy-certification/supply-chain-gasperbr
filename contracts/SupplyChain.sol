pragma solidity ^0.5.0;

contract SupplyChain {

    enum State { ForSale, Sold, Shipped, Received }

    struct Item {
        string name;
        uint price;
        State state;
        address seller;
        address buyer;
    }
    
    uint constant public fee = 1 finney;

    uint public itemIdCount;
  
    mapping(uint => Item) public items;
    
    address public owner;

    event LogForSale(uint itemId);
    event LogSold(uint itemId);
    event LogShipped(uint itemId);
    event LogReceived(uint itemId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the contract owner");
        _;
    }

    modifier checkState(State _requiredState, uint _itemId) {
        require(items[_itemId].seller != address(0), "Item does not exist");
        require(items[_itemId].state == _requiredState, "Item does not have the required state");
        _;
    }
    
    /// @dev checks if sender is buyer or seller of item
    modifier checkCaller(bool _isBuyer, uint _itemId) {
        if (_isBuyer) {
            require(msg.sender == items[_itemId].buyer, "Sender isn't the item's buyer");
        } else {
            require(msg.sender == items[_itemId].seller, "Sender isn't the item's seller");   
        }
        _;
    }

    modifier checkValue(uint _requiredValue) {
        require(msg.value >= _requiredValue, "Ether amount too low");
        _;
    }
    
    modifier returnExcess(uint _required) {
        _;
        if (msg.value > _required) {
            msg.sender.call.value(msg.value - _required)("");
        }
    }

    constructor() public payable {
        owner = msg.sender;
    }

    // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
    function addItem(string memory _name, uint _price)
        public
        payable
        checkValue(fee)
        returnExcess(fee)
        returns (uint)
    {
        Item memory i = Item({
            name: _name,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        
        items[itemIdCount] = i;
        
        emit LogForSale(itemIdCount);
        
        return itemIdCount++;
    }
    
    // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
    function buyItem(uint _itemId)
        public
        payable
        checkState(State.ForSale, _itemId)
        checkValue(items[_itemId].price)
        returnExcess(items[_itemId].price)
    {
        Item storage i = items[_itemId];

        i.seller.call.value(i.price)("");
        i.buyer = msg.sender;
        i.state = State.Sold;
        
        emit LogSold(_itemId);
    }
  
    //Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
    function shipItem(uint _itemId)
        public
        checkState(State.Sold, _itemId)
        checkCaller(false, _itemId)
    {
        Item storage i = items[_itemId];
        i.state = State.Shipped;
        
        emit LogShipped(_itemId);
    }

    // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
    function receiveItem(uint _itemId)
        public
        checkState(State.Shipped, _itemId)
        checkCaller(true, _itemId)
    {
        Item storage i = items[_itemId];
        i.state = State.Received;
        
        emit LogReceived(_itemId);
    }

    // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item. 
    function getItem(uint _itemId)
        public
        view
        returns (string memory, uint, State, address, address)
    {
        Item storage i = items[_itemId];
        
        return (i.name, i.price, i.state, i.seller, i.buyer);
    }

    // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
    function withdrawFunds() public onlyOwner {
        owner.call.value(address(this).balance)("");
    }

}
