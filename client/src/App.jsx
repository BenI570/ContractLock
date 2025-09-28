import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import contractABI from './contract-abi.json';
import PayerView from './components/PayerView';
import CreatorView from './components/CreatorView';

// IMPORTANT: Replace this with your contract's deployed address
const contractAddress = '0x6111544ff49B68afF94b4d2b80c84e49D95a70E7';

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
        const network = await provider.getNetwork();

        console.log("--- DEBUG INFO ---");
        console.log("Contract Address:", contractAddress);
        console.log("Connected Account:", accounts[0]);
        console.log("Network Name:", network.name);
        console.log("Network Chain ID:", Number(network.chainId));
        console.log("--------------------");

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

  const goBack = () => setRole(null);

  if (!account) {
    return (
      <div className="container">
        <h1>Connect to MetaMask</h1>
        <button onClick={connectWallet}>Connect Wallet</button>
      </div>
    );
  }

  if (!role) {
    return (
      <div className="container">
        <h1>Select Your Role</h1>
        <button onClick={() => setRole('payer')}>Payer</button>
        <button onClick={() => setRole('creator')}>Contract Creator</button>
      </div>
    );
  }

  if (role === 'payer') {
    return <PayerView contract={contract} account={account} goBack={goBack} />;
  }

  if (role === 'creator') {
    return <CreatorView contract={contract} goBack={goBack} />;
  }

  return (
    <div className="container">
      <h1>Welcome to ContractLock</h1>
      <p>Account: {account}</p>
    </div>
  );
}

export default App;