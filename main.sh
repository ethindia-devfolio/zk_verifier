#!/bin/bash  

# Set variables for your file names and directories  
CIRCUIT_NAME="DatasetHash"  # Replace with your actual circuit name (without .circom)  
BUILD_DIR="dataset_proof"  
PTAU_FILE="pot12_0000.ptau"  
FINAL_PTAU_FILE="pot12_final.ptau"  
INITIAL_ZKEY="dataset_poseidon_hash_0000.zkey"  
FINAL_ZKEY="dataset_poseidon_hash_final.zkey"  
VERIFICATION_KEY="verification_key.json"  
INPUT_FILE="input.json"  
WITNESS_FILE="witness.wtns"  
PROOF_FILE="proof.json"  
PUBLIC_FILE="public.json"  


echo "----------------------------------"  
echo "Step 1: Compile the Circom circuit"  
echo "----------------------------------"  
circom ${CIRCUIT_NAME}.circom --r1cs --wasm --sym
if [ $? -ne 0 ]; then  
    echo "Error: Failed to compile the circuit."  
    exit 1  
fi  
echo "Circuit compiled successfully!"  

echo "-----------------------------------------"  
echo "Step 2: Generate the Powers of Tau (ptau)"  
echo "-----------------------------------------"  
if [ -f $PTAU_FILE ]; then  
    echo "$PTAU_FILE already exists. Skipping ptau generation."  
else  
    snarkjs powersoftau new bn128 12 $PTAU_FILE -v  
    if [ $? -ne 0 ]; then  
        echo "Error: Failed to generate the ptau file."  
        exit 1  
    fi  

    echo "Contributing to the Powers of Tau ceremony..."  
    snarkjs powersoftau contribute $PTAU_FILE $PTAU_FILE --name="COPESTUDIO" -v -e="AKAVE"  
    if [ $? -ne 0 ]; then  
        echo "Error: Failed during ptau contribution."  
        exit 1  
    fi  
fi  

echo "Preparing for Phase 2..."  
snarkjs powersoftau prepare phase2 $PTAU_FILE $FINAL_PTAU_FILE -v  
if [ $? -ne 0 ]; then  
    echo "Error: Failed to prepare phase 2."  
    exit 1  
fi  

echo "--------------------------------------"  
echo "Step 3: Generate the initial zkey file"  
echo "--------------------------------------"  
snarkjs groth16 setup ${CIRCUIT_NAME}.r1cs $FINAL_PTAU_FILE $INITIAL_ZKEY  
if [ $? -ne 0 ]; then  
    echo "Error: Failed to generate the initial zkey."  
    exit 1  
fi  

echo "------------------------------------------"  
echo "Step 4: Contribute to the Phase 2 ceremony"  
echo "------------------------------------------"  
snarkjs zkey contribute $INITIAL_ZKEY $FINAL_ZKEY --name="1st Contributor" -v -e="your random entropy"  
if [ $? -ne 0 ]; then  
    echo "Error: Failed during zkey contribution."  
    exit 1  
fi  

echo "-------------------------------------------------"  
echo "Step 5: Export the verification key (verification_key.json)"  
echo "-------------------------------------------------"  
snarkjs zkey export verificationkey $FINAL_ZKEY $VERIFICATION_KEY  
if [ $? -ne 0 ]; then  
    echo "Error: Failed to export the verification key."  
    exit 1  
fi  

echo "-----------------------------"  
echo "Step 6: Generate the witness"  
echo "-----------------------------"  
if [ ! -f $INPUT_FILE ]; then  
    echo "Error: Input file $INPUT_FILE not found."  
    exit 1  
fi  

node ${CIRCUIT_NAME}_js/generate_witness.js ${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm $INPUT_FILE $WITNESS_FILE  
if [ $? -ne 0 ]; then  
    echo "Error: Failed to generate the witness."  
    exit 1  
fi  

echo "-----------------------------"  
echo "Step 7: Generate the proof"  
echo "-----------------------------"  
snarkjs groth16 prove $FINAL_ZKEY $WITNESS_FILE $PROOF_FILE $PUBLIC_FILE  
if [ $? -ne 0 ]; then  
    echo "Error: Failed to generate the proof."  
    exit 1  
fi  

echo "-----------------------------"  
echo "Step 8: Verify the proof"  
echo "-----------------------------"  
snarkjs groth16 verify $VERIFICATION_KEY $PUBLIC_FILE $PROOF_FILE  
if [ $? -ne 0 ]; then  
    echo "Error: Proof verification failed."  
    exit 1  
fi  
echo "Proof verified successfully!"  

echo "-----------------------------------"  
echo "Process completed successfully!"  
echo "-----------------------------------"  