pragma solidity ^0.4.8;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenFidelite is Token {
    address owner;

    struct Client{
        address addressClient;
    }

    mapping(address => uint) public totalToken;

    Client[] public clients;


    // MODIFIER 
    modifier clientMustExist(address _addressClient){
        bool exist = false;
        for (uint i=0; i<clients.length; i++)
        {
            if (clients[i].addressClient == _addressClient){
                exist=true;
            }
        }
        if (exist == false) throw;
        _;
    }
    modifier clientMustNotExist(address _addressClient){
        for (uint i=0; i<clients.length; i++)
        {
            if (clients[i].addressClient == _addressClient) throw;
            _;
        }
    }
    modifier ownerMustHaveEnoughToken(uint _sommeTransaction){
        if (totalSupply < _sommeTransaction) throw;
        _;
    }
    modifier isOwner(){
        if(msg.sender != owner) throw; 
        _;
    }


    //FUNCTION
    function TokenFidelite(){
        owner = msg.sender;
        totalSupply = 1000000000; //on initialise à 1 milliard le nombre de token de fidelité que possède le propriétaire du contrat
    }

    //Pour que le propriétaire du contrat puisse ajouter de nouveaux clients
    function addClient(address _addressClient) public clientMustNotExist(_addressClient) isOwner(){
        clients.push(Client({
            addressClient: _addressClient
            }));
    }

    //Pour que le proprietaire du contrat (le commercant par exemple) puisse donner des points de fidelite aux clients
    function transfer(address _to, uint256 _value) returns (bool success) {
        //copie colle du modifier isOwner() pour verifier que c'est bien le propriaitaire du contrat qui veut faire la transaction
        if(msg.sender != owner) throw; 
        //copie colle du modifier clientMustExist() pour etre sur que le beneficiaire fait bien parti des clients
        bool exist = false;
        for (uint i=0; i<clients.length; i++)
        {
            if (clients[i].addressClient == _to){
                exist=true;
            }
        }
        if (exist == false) throw;
        //copie colle du modifier ownerMustHaveEnoughToken()
        if (totalSupply < _value || _value <= 0) throw;

        uint _totalTokenInitial = totalToken[_to]; //pour pouvoir comparer les portefeuilles de maniere à verifier si la transaction a eu lieu
        totalSupply -= _value;
        totalToken[_to] += _value;
        //on verifie qu'il y a bien eu un transfert d'argent en comparant le montant initial et le montant final
        if (totalToken[_to] > _totalTokenInitial)
        {
            Transfer(owner, _to, _value);
            return true;
        }
        else
        {
            return false;
        } 
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        _from = msg.sender; //on s'assure que l'expediteur de l'argent est bien la personne qui appelle la fonction
        //copie colle du modifier clientMustExist() pour etre sur que le beneficiaire fait bien parti des clients
        bool exist = false;
        for (uint i=0; i<clients.length; i++)
        {
            if (clients[i].addressClient == _to){
                exist=true;
            }
        }
        if (exist == false) throw;
        //copie colle du modifier clientMustExist() pour etre sur que l'expediteur fait bien parti des clients
        bool _exist = false;
        for (i=0; i<clients.length; i++)
        {
            if (clients[i].addressClient == _from){
                _exist=true;
            }
        }
        if (_exist == false) throw;

        uint _totalTokenInitial = totalToken[_to]; //pour pouvoir comparer les portefeuilles de maniere a verifier si la transaction a eu lieu
        totalToken[_from] -= _value;
        totalToken[_to] += _value;
        //on verifie qu'il y a bien eu un transfert d'argent en comparant le montant initial et le montant final
        if (totalToken[_to] > _totalTokenInitial)
        {
            Transfer(_from, _to, _value);
            return true;
        }
        else
        {
            return false;
        }
    }

    //Pour que le propritaire du contrat puisse savoir le nombre de point d'un client
    function balanceOfClient(address _addressClient) isOwner() constant returns (uint256 balance) {
        return totalToken[_addressClient];
    }

    //Pour supprimer le contrat 
    function kill() isOwner() {
        suicide(msg.sender);
    }
}