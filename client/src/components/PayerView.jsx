import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

const PayerView = ({ contract, account, goBack }) => {
  const [escrows, setEscrows] = useState([]);
  const [selectedEscrow, setSelectedEscrow] = useState(null);
  const [escrowDetails, setEscrowDetails] = useState(null);

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
        const details = await contract.escrows(escrowId);
        setEscrowDetails(details);
      } catch (error) {
        console.error('Error fetching escrow details:', error);
      }
    }
  };

  const handlePay = async () => {
    if (contract && selectedEscrow && escrowDetails) {
      try {
        const tx = await contract.pay(selectedEscrow, { value: escrowDetails.amountPerPayer });
        await tx.wait();
        alert('Payment successful!');
      } catch (error) {
        console.error('Error making payment:', error);
      }
    }
  };

  return (
    <div className="container">
      <button onClick={goBack} className="back-button">Back</button>
      <h2>Payer View</h2>
      <h3>Your Escrows</h3>
      <ul>
        {escrows.map(escrowId => (
          <li key={escrowId}>
            <button onClick={() => handleSelectEscrow(escrowId)}>
              Escrow #{escrowId}
            </button>
          </li>
        ))}
      </ul>
      {selectedEscrow && escrowDetails && (
        <div>
          <h3>Escrow Details</h3>
          <p>Amount per Payer: {ethers.formatEther(escrowDetails.amountPerPayer)} ETH</p>
          <button onClick={handlePay}>Pay</button>
        </div>
      )}
    </div>
  );
};

export default PayerView;
