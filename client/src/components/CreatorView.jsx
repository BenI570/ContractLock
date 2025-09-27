import { useState } from 'react';
import { ethers } from 'ethers';

const CreatorView = ({ contract }) => {
  const [beneficiary, setBeneficiary] = useState('');
  const [payers, setPayers] = useState('');
  const [amountPerPayer, setAmountPerPayer] = useState('');
  const [deadline, setDeadline] = useState('');

  const handleCreateEscrow = async () => {
    if (contract) {
      try {
        const payersArray = payers.split(',').map(p => p.trim());
        const amount = ethers.parseEther(amountPerPayer);
        const deadlineUnix = Math.floor(new Date(deadline).getTime() / 1000);

        const tx = await contract.createEscrow(
          beneficiary,
          payersArray,
          amount,
          deadlineUnix,
          ethers.ZeroAddress // For native token
        );
        await tx.wait();
        alert('Escrow created successfully!');
      } catch (error) {
        console.error('Error creating escrow:', error);
      }
    }
  };

  return (
    <div>
      <h2>Create Escrow</h2>
      <form onSubmit={(e) => { e.preventDefault(); handleCreateEscrow(); }}>
        <div>
          <label>Beneficiary Address:</label>
          <input type="text" value={beneficiary} onChange={(e) => setBeneficiary(e.target.value)} />
        </div>
        <div>
          <label>Payer Addresses (comma-separated):</label>
          <input type="text" value={payers} onChange={(e) => setPayers(e.target.value)} />
        </div>
        <div>
          <label>Amount Per Payer (ETH):</label>
          <input type="text" value={amountPerPayer} onChange={(e) => setAmountPerPayer(e.target.value)} />
        </div>
        <div>
          <label>Deadline:</label>
          <input type="datetime-local" value={deadline} onChange={(e) => setDeadline(e.target.value)} />
        </div>
        <button type="submit">Create Escrow</button>
      </form>
    </div>
  );
};

export default CreatorView;
