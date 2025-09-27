import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import contractABI from './contract-abi.json';
import PayerView from './components/PayerView';
import CreatorView from './components/CreatorView';

// IMPORTANT: Replace this with your contract's deployed address
const contractAddress = 'YOUR_CONTRACT_ADDRESS';

function App() {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [contract, setContract] = useState(null);
  const [role, setRole] = useState(null); // 'payer' or 'creator'

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.send('eth_requestAccounts', []);
        setAccount(accounts[0]);
        setProvider(provider);
        const signer = await provider.getSigner();
        const contract = new ethers.Contract(contractAddress, contractABI, signer);
        setContract(contract);
      } catch (error) {
        console.error('Error connecting to MetaMask:', error);
      }
    } else {
      alert('Please install MetaMask!');
    }
  };

  if (!account) {
    return (
      <div>
        <h1>Connect to MetaMask</h1>
        <button onClick={connectWallet}>Connect Wallet</button>
      </div>
    );
  }

  if (!role) {
    return (
      <div>
        <h1>Select Your Role</h1>
        <button onClick={() => setRole('payer')}>Payer</button>
        <button onClick={() => setRole('creator')}>Contract Creator</button>
      </div>
    );
  }

  if (role === 'payer') {
    return <PayerView contract={contract} account={account} />;
  }

  if (role === 'creator') {
    return <CreatorView contract={contract} />;
  }

  return (
    <div>
      <h1>Welcome to ContractLock</h1>
      <p>Account: {account}</p>
    </div>
  );
}

export default App;