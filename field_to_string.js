const crypto = require('crypto');  

function stringToFieldElement(str) {  
  // Compute SHA-256 hash  
  const hash = crypto.createHash('sha256').update(str).digest('hex');  
  const bigIntHash = BigInt('0x' + hash);  
  // Field prime (bn128 curve)  
  const Fp = BigInt('21888242871839275222246405745257275088548364400416034343698204186575808495617');  
  // Reduce hash modulo field prime  
  return (bigIntHash % Fp).toString();  
}  

// Your list of strings  
const strings = ["hi", "hello", "hi", "say", "weekend", "luther", "darshan", "arya", "hi", "hey", "hmm", "hi", "sd", "ds", "ji", "ji", "dsd", "sds", "dss", "dsd"];  

// Convert each string to a field element  
const fieldElements = strings.map(s => stringToFieldElement(s));  

console.log("Field Elements:", fieldElements);  