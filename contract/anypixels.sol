// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Anypixels {


    struct Canvas {
        string name;
        address owner;
        bytes32[6] pixels;
        address artist;
        string description;
        uint256 price;
    }

 
    address public owner;

    uint256 public royalty;

    Canvas[] internal canvases;

    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    constructor(uint256 _royalty) reasonableRoyalty(_royalty) {
        royalty = _royalty;
        owner = msg.sender;
    }

    modifier reasonableRoyalty(uint256 _royalty) {
        require (_royalty <= 20, "royalty too high!");
        _;
    }


    function createCanvas(string calldata _name, bytes32[6] calldata _pixels, string calldata _description ,uint256 _price) public {
        require(bytes(_name).length > 0, "Empty name");
        canvases.push(Canvas(
            _name,
            msg.sender, 
            _pixels, 
            msg.sender,
            bytes(_description).length > 0 ? _description : "...",
            _price));
    }

    function setPrice(uint256 _index, uint256 _price) public {
        Canvas storage currentCanvas = canvases[_index];
        require (msg.sender == currentCanvas.owner, "Only holder can change price!");
        require(_price > 0, "Please enter a price!");
        currentCanvas.price = _price;
    }

    function readCanvas(uint256 _index) public view returns (
        string memory,
        address, 
        bytes32[6] memory, 
        address, 
        string memory,
        uint256
    ){
        Canvas storage currentCanvas = canvases[_index];
        return (
            currentCanvas.name, 
            currentCanvas.owner, 
            currentCanvas.pixels, 
            currentCanvas.artist, 
            currentCanvas.description,
            currentCanvas.price
        );
    }

    function getCanvasLength() public view returns(uint256) {
        return canvases.length;
    }

    function buyCanvas(uint256 _index) public {
        Canvas storage currentCanvas = canvases[_index]; 
        require(currentCanvas.owner != msg.sender, "You can't buy canvases you own");
        require(currentCanvas.price > 0, "Canvas isn't on sale");
        uint256 royaltyFee = (currentCanvas.price * royalty) / 100;
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                currentCanvas.artist,
                royaltyFee
            )&&
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                currentCanvas.owner,
                currentCanvas.price - royaltyFee
            ),
          "Transfer failed."
        );
        currentCanvas.price = 0;
        currentCanvas.owner = msg.sender;
    }

    function setRoyalty(uint256 _royalty) public reasonableRoyalty(_royalty) {
        require(msg.sender == owner, "Only contract owner can modify royalty");
        royalty = _royalty;
    }
}

