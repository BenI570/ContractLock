import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

const PayerView = ({ contract, account, goBack }) => {
  const [escrows, setEscrows] = useState([]);
  const [selectedEscrow, setSelectedEscrow] = useState(null);
  const [escrowDetails, setEscrowDetails] = useState(null);
  const [allHavePaid, setAllHavePaid] = useState(false);
  const [beneficiaryClaimed, setBeneficiaryClaimed] = useState(false);
  const [paying, setPaying] = useState(false);
  const [userDeposit, setUserDeposit] = useState(0);

  useEffect(() => {
    const getEscrows = async () => {
      if (contract) {
        try {
          const userEscrows = await contract.getUserEscrows(account);
          setEscrows(userEscrows.map(escrowId => escrowId.toString()));
        } catch (error) {
          console.error('Error fetching user escrows:', error);
        }
      }
    };
    getEscrows();
  }, [contract, account]);

  const handleSelectEscrow = async (escrowId) => {
    setSelectedEscrow(escrowId);
    if (contract) {
      try {
        const details = await contract.getEscrowDetails(escrowId);
        const allPaid = await contract.allPaid(escrowId);
        const deposit = await contract.depositedOf(escrowId, account);
        setEscrowDetails(details);
        setAllHavePaid(allPaid);
        setUserDeposit(deposit);
        setBeneficiaryClaimed(details.beneficiaryClaimed);
      } catch (error) {
        console.error('Error fetching escrow details:', error);
      }
    }
  };

  const handlePay = async () => {
    if (contract && selectedEscrow && escrowDetails) {
      setPaying(true);
      try {
        const tx = await contract.pay(selectedEscrow, { value: escrowDetails.amountPerPayer });
        await tx.wait();
        alert('Payment successful!');
        const allPaid = await contract.allPaid(selectedEscrow);
        const deposit = await contract.depositedOf(selectedEscrow, account);
        setAllHavePaid(allPaid);
        setUserDeposit(deposit);
      } catch (error) {
        console.error('Error making payment:', error);
      } finally {
        setPaying(false);
      }
    }
  };

  const handleWithdraw = async () => {
    if (contract && selectedEscrow) {
      try {
        const tx = await contract.withdrawRefund(selectedEscrow);
        await tx.wait();
        alert('Withdrawal successful!');
        handleSelectEscrow(selectedEscrow); // Refresh details
      } catch (error) {
        console.error('Error withdrawing refund:', error);
      }
    }
  };

  const handleClaim = async () => {
    if (contract && selectedEscrow) {
      try {
        const tx = await contract.claimBeneficiary(selectedEscrow);
        await tx.wait();
        alert('Funds claimed successfully!');
        handleSelectEscrow(selectedEscrow); // Refresh details
      } catch (error) {
        console.error('Error claiming funds:', error);
      }
    }
  };

  const isDeadlinePassed = () => {
    if (!escrowDetails) return false;
    return new Date().getTime() / 1000 > escrowDetails.deadline;
  };

  const showPayButton = () => {
    if (!escrowDetails) return false;
    return (
      !isDeadlinePassed() &&
      userDeposit == 0 &&
      account.toLowerCase() !== escrowDetails.beneficiary.toLowerCase()
    );
  };

  return (
    <div className="container">
      <button onClick={goBack} className="back-button">Back</button>
      <h2>Payer View</h2>
      <h3>Your Escrows</h3>
      <ul>
        {escrows.map((escrowId, i) => (
          <li key={escrowId}>
            <button onClick={() => handleSelectEscrow(escrowId)}>
              Escrow #{i + 1}
            </button>
          </li>
        ))}
      </ul>
      {selectedEscrow && escrowDetails && (
        <div>
          <h3>Escrow Details</h3>
          <p>Beneficiary: {escrowDetails.beneficiary}</p>
          <p>Amount per Payer: {ethers.formatEther(escrowDetails.amountPerPayer)} ETH</p>
          <p>Deadline: {new Date(Number(escrowDetails.deadline) * 1000).toLocaleString()}</p>
          <p>All Payers Have Paid: {allHavePaid || beneficiaryClaimed ? 'Yes' : 'No'}</p>
          {selectedEscrow && escrowDetails && (
            <>
              {account.toLowerCase() === escrowDetails.beneficiary.toLowerCase() && beneficiaryClaimed && (
                <p>You have already claimed.</p>
              )}
              {userDeposit > 0 && (
                <p>You have already paid.</p>
              )}
              {isDeadlinePassed() && !allHavePaid && userDeposit === 0 && (
                <p>You have withdrawn your funds.</p>
              )}
            </>
          )}

          {showPayButton() && (
            <button onClick={handlePay} disabled={paying}>
              {paying ? 'Paying...' : 'Pay'}
            </button>
          )}

          {isDeadlinePassed() && !allHavePaid && userDeposit > 0 && !beneficiaryClaimed && (
            <button onClick={handleWithdraw} disabled={paying}>Withdraw Refund</button>
          )}

          {allHavePaid && account.toLowerCase() === escrowDetails.beneficiary.toLowerCase() && (
            <button onClick={handleClaim}>Claim Funds</button>
          )}
        </div>
      )}
    </div>
  );
};

export default PayerView;
