
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractLock {
    struct Escrow {
        address creator;
        address beneficiary;
        uint256 amountPerPayer;
        uint256 deadline;
        address[] payers;
        mapping(address => uint256) deposited;
        bool beneficiaryClaimed;
        address token; // Address of the ERC20 token, or address(0) for native currency
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
        escrowId = nextEscrowId;
        Escrow storage newEscrow = escrows[escrowId];
        newEscrow.creator = msg.sender;
        newEscrow.beneficiary = _beneficiary;
        newEscrow.amountPerPayer = _amountPerPayer;
        newEscrow.deadline = _deadlineUnix;
        newEscrow.token = _tokenAddress;

        for (uint i = 0; i < _payers.length; i++) {
            newEscrow.payers.push(_payers[i]);
            userEscrows[_payers[i]].push(escrowId);
        }
        userEscrows[msg.sender].push(escrowId); // Creator can also be a payer

        nextEscrowId++;
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

    function pay(uint256 escrowId) external payable {
        Escrow storage escrow = escrows[escrowId];
        require(block.timestamp < escrow.deadline, "Deadline has passed");
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
