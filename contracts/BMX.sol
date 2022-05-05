// SPDX-License-Identifier: MIT

/**
 * @title Smart contract for BMX token
 * @author Stenor Tanaka
 */
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Stakable.sol";

contract BMX is Ownable, Stakeable {
    /**
     * @notice Our Tokens required variables that are needed to operate everything
     */
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address private _adminAccount;
    uint8 public restrictPercentage = 5; /// @notice Token holders can sell only 5% of their presaled Balances in a month.
    uint256 private _publicSaleDate; /// @notice The date that the public sale started.
    uint256 private _wastingFee = 2;

    /**
     * @notice _balances is a mapping that contains a address as KEY
     * and the balance of the address as the value
     */
    mapping(address => uint256) private _balances;

    /**
     * @notice _presaledBalances is a mapping that contains a address as KEY
     * and the transferable balance of the address as the value
     */
    mapping(address => uint256) private _presaledBalances;

    /**
     * @notice _allowances is used to manage and control allownace
     * An allowance is the right to use another accounts balance, or part of it
     */
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @notice Events are created below.
     * Transfer event is a event that notify the blockchain that a transfer of assets has taken place
     *
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @notice Approval is emitted when a new Spender is approved to spend Tokens on
     * the Owners account
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @notice This modifier is to restrict that the users can't transfer more than 5% of thier balance per month.
     */
    modifier restrictTransfer(address account, uint256 amount) {
        require(
            _balances[account] >= amount,
            "BMX: cant transfer more than your account holds"
        );
        uint256 _transferableBalance = _transferableToken(account);
        require(
            amount <= _transferableBalance,
            "BMX: Over 5% of your presale balance"
        );
        require(
            amount + _wastingFee <= _transferableBalance,
            "BMX: Insufficient BMX for gas"
        );
        _;
    }

    /**
     * @notice constructor will be triggered when we create the Smart contract
     * _name = name of the token
     * _short_symbol = Short Symbol name for the token
     * token_decimals = The decimal precision of the Token, defaults 18
     * _totalSupply is how much Tokens there are totally
     * max_transferable_percentage is how much Tokens users can transfer in a month
     */
    constructor(
        string memory token_name,
        string memory short_symbol,
        uint8 token_decimals,
        uint256 token_totalSupply,
        address token_adminAccount
    ) {
        _name = token_name;
        _symbol = short_symbol;
        _decimals = token_decimals;
        _totalSupply = token_totalSupply;
        _adminAccount = token_adminAccount;

        // Add all the tokens created to the creator of the token
        _balances[msg.sender] = _totalSupply;

        // Emit an Transfer event to notify the blockchain that an Transfer has occured
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @notice decimals will return the number of decimal precision the Token is deployed with
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice symbol will return the Token's symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice name will return the Token's symbol
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice totalSupply will return the tokens total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice balanceOf will return the account balance for the given account
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function adminAccount() external view returns (address) {
        return _adminAccount;
    }

    /**
     * @notice Percentage of transferable Token
     */
    function maxTransferablePercentage() external view returns (uint8) {
        return restrictPercentage;
    }

    /**
     * @notice Start the public sale
     */
    function publicSaleStart() public onlyOwner {
        _publicSaleDate = block.timestamp;
    }

    /**
     * @notice Set wasting fee
     */
    function setWastingFee(uint256 wastingFee) public onlyOwner {
        _wastingFee = wastingFee;
    }

    /**
     * @notice calcMonth is the number of months the public sale was performed.
     * If the return value is more than 20, it will return 20.
     */
    function _calcMonth() internal view returns (uint256) {
        uint256 monthCount = 1 + (block.timestamp - _publicSaleDate) / 30 days;
        if (monthCount > 20) monthCount = 20;
        return monthCount;
    }

    /**
     * @notice transferableToken() is a function to calculate the transferable amount of token for one user.
     * @param account : user address
     */
    function _transferableToken(address account) internal view returns (uint256) {
        uint256 _nubmerOfMonths = _calcMonth();
        uint256 _transferableBalance = _balances[account] -
            ((100 - restrictPercentage * _nubmerOfMonths) *
                _presaledBalances[account]) /
            100;
        return _transferableBalance;
    }

    /**
     * @notice _mint will create tokens on the address inputted and then increase the total supply
     *
     * It will also emit an Transfer event, with sender set to zero address (adress(0))
     *
     * Requires that the address that is recieveing the tokens is not zero address
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BMX: cannot mint to zero address");

        // Increase total supply
        _totalSupply = _totalSupply + (amount);
        // Add amount to the account balance using the balance mapping
        _balances[account] = _balances[account] + amount;
        // Emit our event to log the action
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice _burn will destroy tokens from an address inputted and then decrease total supply
     * An Transfer event will emit with receiever set to zero address
     *
     * Requires
     * - Account cannot be zero
     * - Account balance has to be bigger or equal to amount
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BMX: cannot burn from zero address");
        require(
            _balances[account] >= amount,
            "BMX: Cannot burn more than the account owns"
        );

        // Remove the amount from the account balance
        _balances[account] = _balances[account] - amount;
        // Decrease totalSupply
        _totalSupply = _totalSupply - amount;
        // Emit event, use zero address as reciever
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice burn is used to destroy tokens on an address
     *
     * See {_burn}
     * Requires
     *   - msg.sender must be the token owner
     *
     */
    function burn(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _burn(account, amount);
        return true;
    }

    /**
     * @notice mint is used to create tokens and assign them to msg.sender
     *
     * See {_mint}
     * Requires
     *   - msg.sender must be the token owner
     *
     */
    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        if (_publicSaleDate == 0)
            _presaledBalances[account] = _presaledBalances[account] + amount;
        return true;
    }

    /**
     * @notice transfer is used to transfer funds from the sender to the recipient
     * This function is only callable from outside the contract. For internal usage see
     * _transfer
     *
     * Requires
     * - Caller cannot be zero
     * - Caller must have a balance = or bigger than amount
     *
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function adminTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(
            msg.sender == _adminAccount,
            "BMX: only admin account can make this transfer"
        );
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @notice _transfer is used for internal transfers
     *
     * Events
     * - Transfer
     *
     * Requires
     *  - modifier restrictTransfer() is used
     *  - Sender cannot be zero
     *  - recipient cannot be zero
     *  - sender balance most be = or bigger than amount + wasting Fee
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal restrictTransfer(sender, amount) {
        require(sender != address(0), "BMX: transfer from zero address");
        require(recipient != address(0), "BMX: transfer to zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        _burn(sender, _wastingFee);

				if (_publicSaleDate == 0) {
					_presaledBalances[sender] = _presaledBalances[sender] - amount;
					_presaledBalances[recipient] = _presaledBalances[recipient] + amount;
				}

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice getOwner just calls Ownables owner function.
     * returns owner of the token
     *
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @notice allowance is used view how much allowance an spender has
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice approve will use the senders address and allow the spender to use X amount of tokens on his behalf
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice _approve is used to add a new Spender to a Owners account
     *
     * Events
     *   - {Approval}
     *
     * Requires
     *   - owner and spender cannot be zero address
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "BMX: approve cannot be done from zero address"
        );
        require(
            spender != address(0),
            "BMX: approve cannot be to zero address"
        );
        // Set the allowance of the spender address at the Owner mapping over accounts to the amount
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice transferFrom is uesd to transfer Tokens from a Accounts allowance
     * Spender address should be the token holder
     *
     * Requires
     *   - The caller must have a allowance = or bigger than the amount spending
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        // Make sure spender is allowed the amount
        require(
            _allowances[spender][msg.sender] >= amount,
            "BMX: You cannot spend that much on this account"
        );
        // Transfer first
        _transfer(spender, recipient, amount);
        // Reduce current allowance so a user cannot respend
        _approve(
            spender,
            msg.sender,
            _allowances[spender][msg.sender] - amount
        );
        return true;
    }

    /**
     * @notice increaseAllowance
     * Adds allowance to a account from the function caller address
     */
    function increaseAllowance(address spender, uint256 amount)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + amount
        );
        return true;
    }

    /**
     * @notice decreaseAllowance
     * Decrease the allowance on the account inputted from the caller address
     */
    function decreaseAllowance(address spender, uint256 amount)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - amount
        );
        return true;
    }

    /**
     * Add functionality like burn to the _stake afunction
     *
     */
    function stake(uint256 _amount, address account) public {
        // Make sure staker actually is good for it
        require(
            _amount < _balances[account],
            "BMX: Cannot stake more than you own"
        );

        _stake(_amount, account);
        // Burn the amount of tokens on the sender
        _burn(account, _amount);
    }

    /**
     * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake(address account, uint256 amount) public {
        StakingSummary memory summary = StakingSummary(
            0,
            stakeholders[stakes[account]].address_stakes
        );
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimable = availableReward;
            _withdrawStake(summary.stakes[s].amount, s, account);
        }
        // Return staked tokens to user
        _mint(account, amount);
    }
}