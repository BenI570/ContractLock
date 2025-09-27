
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ContractLock is ReentrancyGuard {
    struct Escrow {
        address creator;
        address beneficiary;
        uint256 amountPerPayer;
        uint256 deadline;
        address[] payers;
        mapping(address => bool) isPayer;
        mapping(address => uint256) deposited;
        uint256 totalDeposited;
        bool beneficiaryClaimed;
        IERC20 token; // address(0) = native token
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public nextEscrowId;
    mapping(address => uint256[]) public userEscrows;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed creator,
        address indexed beneficiary,
        uint256 amountPerPayer,
        uint256 deadline,
        address[] payers,
        address token
    );
    event Paid(uint256 indexed escrowId, address indexed payer, uint256 amount);
    event BeneficiaryClaimed(
        uint256 indexed escrowId,
        address indexed beneficiary,
        uint256 amount
    );
    event RefundWithdrawn(
        uint256 indexed escrowId,
        address indexed payer,
        uint256 amount
    );

    function createEscrow(
        address _beneficiary,
        address[] calldata _payers,
        uint256 _amountPerPayer,
        uint256 _deadlineUnix,
        address _tokenAddress
    ) external returns (uint256 escrowId) {
        require(_beneficiary != address(0), "invalid beneficiary");
        require(_payers.length > 0, "need payers");
        require(_amountPerPayer > 0, "amount > 0");
        require(_deadlineUnix > block.timestamp, "deadline in future");

        escrowId = nextEscrowId++;
        Escrow storage e = escrows[escrowId];
        e.creator = msg.sender;
        e.beneficiary = _beneficiary;
        e.amountPerPayer = _amountPerPayer;
        e.deadline = _deadlineUnix;
        e.token = _tokenAddress == address(0) ? IERC20(address(0)) : IERC20(_tokenAddress);

        for (uint i = 0; i < _payers.length; i++) {
            address p = _payers[i];
            require(p != address(0), "invalid payer");
            require(!e.isPayer[p], "duplicate payer");
            e.isPayer[p] = true;
            e.payers.push(p);
            userEscrows[p].push(escrowId);
        }
        userEscrows[msg.sender].push(escrowId);

        emit EscrowCreated(
            escrowId,
            msg.sender,
            _beneficiary,
            _amountPerPayer,
            _deadlineUnix,
            _payers,
            _tokenAddress
        );
    }

    function pay(uint256 escrowId) external payable nonReentrant {
        Escrow storage e = escrows[escrowId];
        require(e.isPayer[msg.sender], "not a registered payer");
        require(block.timestamp <= e.deadline, "deadline passed");
        require(e.deposited[msg.sender] == 0, "already paid");

        if (address(e.token) == address(0)) {
            // native token
            require(msg.value == e.amountPerPayer, "send exact amount");
            e.deposited[msg.sender] = msg.value;
        } else {
            // ERC-20 token
            require(msg.value == 0, "do not send native token");
            require(e.token.transferFrom(msg.sender, address(this), e.amountPerPayer), "transfer failed");
            e.deposited[msg.sender] = e.amountPerPayer;
        }

        e.totalDeposited += e.amountPerPayer;
        emit Paid(escrowId, msg.sender, e.amountPerPayer);
    }

    function allPaid(uint256 escrowId) public view returns (bool) {
        Escrow storage e = escrows[escrowId];
        return e.totalDeposited == e.amountPerPayer * e.payers.length;
    }

    function claimBeneficiary(uint256 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        require(msg.sender == e.beneficiary, "only beneficiary");
        require(!e.beneficiaryClaimed, "already claimed");
        require(allPaid(escrowId), "not all paid");
        require(block.timestamp <= e.deadline, "deadline passed");

        e.beneficiaryClaimed = true;
        uint256 amount = e.totalDeposited;
        e.totalDeposited = 0;

        if (address(e.token) == address(0)) {
            (bool ok, ) = e.beneficiary.call{value: amount}("");
            require(ok, "transfer failed");
        } else {
            require(e.token.transfer(e.beneficiary, amount), "transfer failed");
        }

        emit BeneficiaryClaimed(escrowId, e.beneficiary, amount);
    }

    function withdrawRefund(uint256 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        require(block.timestamp > e.deadline, "deadline not passed");
        require(e.isPayer[msg.sender], "not a registered payer");
        require(!allPaid(escrowId), "everyone paid -- no refunds");

        uint256 bal = e.deposited[msg.sender];
        require(bal > 0, "no deposit");

        e.deposited[msg.sender] = 0;
        e.totalDeposited -= bal;

        if (address(e.token) == address(0)) {
            (bool ok, ) = msg.sender.call{value: bal}("");
            require(ok, "refund failed");
        }
        else {
            require(e.token.transfer(msg.sender, bal), "refund failed");
        }

        emit RefundWithdrawn(escrowId, msg.sender, bal);
    }

    // Getter functions for frontend
    function getUserEscrows(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userEscrows[user];
    }

    function depositedOf(uint256 escrowId, address payer)
        external
        view
        returns (uint256)
    {
        return escrows[escrowId].deposited[payer];
    }

    function getEscrowPayers(uint256 escrowId)
        external
        view
        returns (address[] memory)
    {
        return escrows[escrowId].payers;
    }

    function getEscrowToken(uint256 escrowId)
        external
        view
        returns (address)
    {
        return address(escrows[escrowId].token);
    }

    function getEscrowDetails(uint256 escrowId)
        external
        view
        returns (
            address creator,
            address beneficiary,
            uint256 amountPerPayer,
            uint256 deadline,
            bool beneficiaryClaimed,
            address token
        )
    {
        Escrow storage escrow = escrows[escrowId];
        return (
            escrow.creator,
            escrow.beneficiary,
            escrow.amountPerPayer,
            escrow.deadline,
            escrow.beneficiaryClaimed,
            address(escrow.token)
        );
    }
}
"Deadline has passed");
        require(
            msg.value == escrow.amountPerPayer,
            "Incorrect payment amount"
        );

        bool isPayer = false;
        for (uint i = 0; i < escrow.payers.length; i++) {
            if (escrow.payers[i] == msg.sender) {
                isPayer = true;
                break;
            }
        }
        require(isPayer, "Not a designated payer");
        require(
            escrow.deposited[msg.sender] == 0,
            "Payer has already deposited"
        );

        escrow.deposited[msg.sender] = msg.value;
        emit Paid(escrowId, msg.sender, msg.value);
    }

    function allPaid(uint256 escrowId) public view returns (bool) {
        Escrow storage escrow = escrows[escrowId];
        for (uint i = 0; i < escrow.payers.length; i++) {
            if (escrow.deposited[escrow.payers[i]] == 0) {
                return false;
            }
        }
        return true;
    }

    function claimBeneficiary(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(
            msg.sender == escrow.beneficiary,
            "Only beneficiary can claim"
        );
        require(allPaid(escrowId), "Not all payers have deposited");
        require(!escrow.beneficiaryClaimed, "Beneficiary has already claimed");

        uint256 totalAmount = escrow.amountPerPayer * escrow.payers.length;
        escrow.beneficiaryClaimed = true;

        (bool success, ) = payable(escrow.beneficiary).call{
            value: totalAmount
        }("");
        require(success, "Transfer failed");

        emit BeneficiaryClaimed(escrowId, escrow.beneficiary, totalAmount);
    }

    function withdrawRefund(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(
            block.timestamp >= escrow.deadline,
            "Deadline has not passed yet"
        );
        require(!allPaid(escrowId), "All payers have paid, no refund");

        uint256 amountToRefund = escrow.deposited[msg.sender];
        require(amountToRefund > 0, "No deposit to refund");

        escrow.deposited[msg.sender] = 0; // Prevent re-entrancy

        (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
        require(success, "Refund transfer failed");

        emit RefundWithdrawn(escrowId, msg.sender, amountToRefund);
    }

    // Getter functions for frontend
    function getUserEscrows(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userEscrows[user];
    }

    function depositedOf(uint256 escrowId, address payer)
        external
        view
        returns (uint256)
    {
        return escrows[escrowId].deposited[payer];
    }

    function getEscrowPayers(uint256 escrowId)
        external
        view
        returns (address[] memory)
    {
        return escrows[escrowId].payers;
    }

    function getEscrowToken(uint256 escrowId)
        external
        view
        returns (address)
    {
        return escrows[escrowId].token;
    }

    function getEscrowDetails(uint256 escrowId)
        external
        view
        returns (
            address creator,
            address beneficiary,
            uint256 amountPerPayer,
            uint256 deadline,
            bool beneficiaryClaimed,
            address token
        )
    {
        Escrow storage escrow = escrows[escrowId];
        return (
            escrow.creator,
            escrow.beneficiary,
            escrow.amountPerPayer,
            escrow.deadline,
            escrow.beneficiaryClaimed,
            escrow.token
        );
    }
}
