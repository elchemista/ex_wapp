//! Signal Protocol session management
//! 
//! This module handles the Double Ratchet algorithm state.

/// Session state for Signal Protocol communication
#[derive(Clone)]
pub struct SessionState {
    /// Root key for the current ratchet
    pub root_key: [u8; 32],
    
    /// Current sending chain key
    pub sending_chain_key: [u8; 32],
    
    /// Current receiving chain key  
    pub receiving_chain_key: Option<[u8; 32]>,
    
    /// Current message counter (sending)
    pub sending_counter: u32,
    
    /// Previous chain counter
    pub previous_counter: u32,
    
    /// Our current ratchet key pair
    pub ratchet_private: [u8; 32],
    pub ratchet_public: [u8; 32],
    
    /// Their current ratchet public key
    pub remote_ratchet_key: Option<[u8; 32]>,
    
    /// Identity keys
    pub local_identity_public: [u8; 32],
    pub remote_identity_public: [u8; 32],
}
