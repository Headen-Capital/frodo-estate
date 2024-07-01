// AddProperty.js
import React, { useState } from "react";
import { useSendTransaction } from "wagmi";
import { useAccount } from "wagmi";
import ethers from "ethers";
import propertyNFT from "../../out/PropertyNFT.sol/PropertyNFT.json";
import { WalletButton } from "components/WalletButton";

const KYCABI = []; // Your KYC contract ABI

const AddProperty = async () => {
  const propertyNFTAddress = "0x7d5524041A6630352C761ddBB360226e0e6140EF";
  const kycAddress = "0xB5644397a9733f86Cacd928478B29b4cD6041C45";

  const [tokenURI, setTokenURI] = useState("");
  const [initialValue, setInitialValue] = useState("");
  const [usage, setUsage] = useState("Flip"); // Assuming 'Flip', 'Rent', 'Build' as options
  const [loading, setLoading] = useState(false);

  const account = useAccount();
  const { sendTransaction } = useSendTransaction();

  const propertyNFTContract = new ethers.Contract(
    propertyNFTAddress,
    propertyNFT.abi
    // (await account.connector?.getProvider()) as any
  );

  const kycContract = new ethers.Contract(kycAddress, KYCABI);

  const addProperty = async () => {
    setLoading(true);
    try {
      // Check if the partner is KYC verified
      const isVerified = await kycContract.methods
        .isVerified(account.address)
        .call();

      if (!isVerified) {
        alert("You must be a verified partner to add a property.");
        setLoading(false);
        return;
      }

      // Mint the new property NFT
      const txn = await propertyNFTContract.populateTransaction?.mintProperty?.(
        tokenURI,
        usage,
        initialValue,
        account.address
      );

      sendTransaction({
        to: txn?.to as `0x${string}`,
        data: txn?.data as `0x${string}`,
        value: txn?.value as unknown as bigint,
      });

      // Assuming the mintProperty function returns the tokenId of the newly minted NFT
      const tokenId = await propertyNFTContract.methods
        .mintProperty(tokenURI, usage, initialValue, account.address)
        .call();

      alert("Property added and vault created successfully!");
    } catch (error) {
      console.error("Error adding property or creating vault:", error);
      alert("An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <WalletButton />
      <h2>Add Property</h2>
      <input
        type="text"
        value={tokenURI}
        onChange={(e) => setTokenURI(e.target.value)}
        placeholder="Token URI"
      />
      <select value={usage} onChange={(e) => setUsage(e.target.value)}>
        <option value="Flip">Flip</option>
        <option value="Rent">Rent</option>
        <option value="Build">Build</option>
      </select>
      <input
        type="number"
        value={initialValue}
        onChange={(e) => setInitialValue(e.target.value)}
        placeholder="Initial Value"
      />
      <button onClick={addProperty} disabled={loading}>
        {loading ? "Processing..." : "Add Property"}
      </button>
    </div>
  );
};

export default AddProperty;
