import csv  
import hashlib  
import json  # Added import for json module  
  
# Poseidon parameters (these are example placeholder parameters)  
# For a secure implementation, generate parameters according to the Poseidon specification  
  
# Prime field (BN254 curve prime)  
p = 21888242871839275222246405745257275088548364400416034343698204186575808495617  
  
# Poseidon parameters  
t = 3  # Width of the state (number of elements in the state)  
n_rounds_f = 8  # Number of full rounds  
n_rounds_p = 57  # Number of partial rounds  
  
# Calculate total number of round constants needed  
total_constants = n_rounds_f * t + n_rounds_p  
  
# Placeholder round constants (simple sequence for demonstration)  
round_constants = [i for i in range(total_constants)]  
  
# Placeholder MDS matrix (identity matrix for simplicity)  
MDS_matrix = [  
    [1 if i == j else 0 for j in range(t)]  
    for i in range(t)  
]  
  
def poseidon_hash(inputs):  
    state = inputs.copy()  
    constants_iter = iter(round_constants)  
  
    # First half of full rounds  
    for _ in range(n_rounds_f // 2):  
        # Add round constants  
        state = [(state[i] + next(constants_iter)) % p for i in range(t)]  
        # Apply S-box (x^5 mod p)  
        state = [pow(s, 5, p) for s in state]  
        # Mix with MDS matrix  
        state = mds_multiply(state)  
  
    # Partial rounds  
    for _ in range(n_rounds_p):  
        # Add round constant to first element  
        state[0] = (state[0] + next(constants_iter)) % p  
        # Apply S-box to first element  
        state[0] = pow(state[0], 5, p)  
        # Mix with MDS matrix  
        state = mds_multiply(state)  
  
    # Second half of full rounds  
    for _ in range(n_rounds_f // 2):  
        # Add round constants  
        state = [(state[i] + next(constants_iter)) % p for i in range(t)]  
        # Apply S-box (x^5 mod p)  
        state = [pow(s, 5, p) for s in state]  
        # Mix with MDS matrix  
        state = mds_multiply(state)  
  
    # Return the first element as the hash output  
    return state[0]  
  
def mds_multiply(state):  
    result = [0] * t  
    for i in range(t):  
        for j in range(t):  
            result[i] = (result[i] + MDS_matrix[i][j] * state[j]) % p  
    return result  
  
def main():  
    # Initialize the list to store finite field elements  
    finite_field_array = []  
  
    # Read the CSV file  
    with open('data.csv', 'r', encoding='utf-8') as csvfile:  
        reader = csv.reader(csvfile)  
        for row_index, row in enumerate(reader):  
            if len(row) != 16:  
                print(f"Skipping row {row_index + 1}: Expected 16 fields but got {len(row)}.")  
                continue  
  
            # Process each field in the row  
            for field_index, field in enumerate(row):  
                field = field.strip()  
  
                # Compute SHA-256 hash of the field  
                hash_obj = hashlib.sha256(field.encode('utf-8'))  
                hash_hex = hash_obj.hexdigest()  
  
                # Convert the hash to a big integer  
                hash_int = int(hash_hex, 16)  
  
                # Map the hash to a finite field element  
                finite_field_element = hash_int % p  
  
                # Collect the finite field elements  
                finite_field_array.append(finite_field_element)  
  
    # Initialize state with zeros  
    state = [0] * t  
  
    # Process the finite_field_array in chunks  
    for i in range(0, len(finite_field_array), t - 1):  
        chunk = finite_field_array[i:i + t - 1]  
  
        # If the chunk is smaller than t - 1, pad it with zeros  
        if len(chunk) < t - 1:  
            chunk += [0] * (t - 1 - len(chunk))  
  
        # Absorb the chunk into the state  
        inputs = [(state[j] + chunk[j]) % p for j in range(t - 1)]  
        inputs.append(state[-1])  # Include the last element of the state  
  
        # Compute the new state  
        state_value = poseidon_hash(inputs)  
        # Create a new state with the hash value and zeros  
        state = [state_value] + [0] * (t - 1)  # Reset other elements to zero  
  
    # The final Poseidon hash of the entire array  
    final_hash = state[0]  
  
    # Prepare data for JSON output  
    # Convert finite field array elements to hex strings  
    finite_field_array_hex = [hex(elem) for elem in finite_field_array]  
    final_hash_hex = hex(final_hash)  
  
    # Prepare the data dictionary  
    output_data = {  
        "data": finite_field_array_hex,  
        "expectedHash": final_hash_hex  
    }  
  
    # Write the data to input.json  
    with open('input.json', 'w') as json_file:  
        json.dump(output_data, json_file, indent=4)  
  
if __name__ == "__main__":  
    main()  