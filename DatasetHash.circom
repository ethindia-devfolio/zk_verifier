pragma circom 2.2.1;  

include "circomlib/circuits/poseidon.circom";  

template DatasetPoseidonHash(n) {  
    // Input signals (private by default)  
    signal input data[n];         // Private input: dataset  
    signal input expectedHash;    // Expected Poseidon hash  

    signal output computedHash;   // Output: Computed hash  

    // Instantiate Poseidon hash function with n inputs  
    component hash = Poseidon(n);  

    // Connect data inputs to the Poseidon hash component  
    for (var i = 0; i < n; i++) {  
        hash.inputs[i] <== data[i];  
    }  

    // Assign the output of Poseidon hash to computedHash  
    computedHash <== hash.out;  

    // Enforce that the computed hash matches the expected hash  
    expectedHash === computedHash;  
}  

// Instantiate the main component with n = 16, specifying public signals  
component main { public [expectedHash] } = DatasetPoseidonHash(16);  