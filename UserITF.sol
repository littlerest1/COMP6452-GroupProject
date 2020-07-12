pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// This file contains the interface class which contains management functions for normal users
contract UserITF {
    /**
    * Structures
    **/
    struct User {
        string name;
        int unusedCredits;   // unused credits that could be used to exchange prizes
        int usedCredits;  // used credits that could be only counted for a part of the total credit
    }
    
    struct Review {
        uint id;
        address author;
        string restaurant;
        string content;
        int credits;
        string receipt;
    }
    
    struct Comment {
        uint review;
        address author;
        bool positive;
        string comment;
        string receipt;
    }
    
    struct CouponType {
        string restaurant;
        uint value; // the value for the coupon
        int rest;  // the number of the rest available
    }
    
    struct Coupon {
        address owner;
        uint couponType;
    }
    
    mapping (address => User) public users;

    Review[] public reviews;
    Comment[] public comments;
    CouponType[] public couponTypes;
    Coupon[] public coupons;
    
    uint review_count = 0;
    
    /**
    * Modifiers
    **/
    modifier accountNotExists(){
        require(bytes(users[msg.sender].name).length == 0);
        _;
    }

    modifier accountExists(){
        require(bytes(users[msg.sender].name).length != 0);
        _;
    }

    modifier notEmpty(string memory content){
        require(bytes(content).length != 0);
        _;
    }
    
    /**
    * Functions
    **/
    // Account Management funcions
    function register(string memory username) public accountNotExists notEmpty(username) returns (bool) {
        User memory u;
        u.name = username;
        u.unusedCredits = 0;
        u.usedCredits = 0;

        users[msg.sender] = u;
        return true;
    }
    
    // Review Management functions
    
    // return true if review successfully recorded
    // else return false
    function newReview(string memory receiptNo, string memory rest_name, string memory review) 
        public accountExists notEmpty(receiptNo) notEmpty(review) notEmpty(rest_name) returns (int credit) {
        address author = msg.sender;

        // check receipt validity
        if (authenticate(receiptNo, rest_name)) {
            Review memory r;
            r.id = review_count;
            review_count ++;
            r.author = author;
            r.restaurant = rest_name;
            r.content = review;
            r.credits = calculateForNewReview(author); // initial credit based on the author's credits
            r.receipt = receiptNo;

            reviews.push(r);
            
            users[author].unusedCredits += r.credits; // change user credit
            
            return r.credits;
        }
        else{
            return -1;
        }
    }
    
    // return reviews with credit sorting
    function searchReview(string memory rest_name) public returns (Review[] memory reviews){
        Review[] memory reviews = backendSearchReview(rest_name);
        return reviews;
    }

    function newComment(uint reviewNo, string memory comment, string memory receiptNo, bool positive) 
        public accountExists notEmpty(receiptNo) notEmpty(comment) returns (int){
        string memory rest_name = reviews[reviewNo].restaurant;
        if (authenticate(receiptNo, rest_name)) {
            Comment memory c;
            c.review = reviewNo;
            c.author = msg.sender;
            c.comment = comment;
            c.positive = positive;
            c.receipt = receiptNo;
            
            comments.push(c);
            
            // get new writer and commentor credits
            (int authorCredit, int commentorCredit) = calculateForNewComment(positive, msg.sender, reviews[reviewNo].author);
            
            // update to the database
            users[reviews[reviewNo].author].unusedCredits += authorCredit;
            users[msg.sender].unusedCredits += commentorCredit;
            
            return commentorCredit;
        }
        else{
            return 0;
        }
    }

    // Credit Management functions
    function checkCredit() public accountExists returns (int unusedCredits, CouponType[] memory available_coupons) {
        return (users[msg.sender].unusedCredits, check_available_coupons(msg.sender));
    }

    function exchangeCoupon(string memory rest_name, uint value, int num) public accountExists returns (string memory){
        // check account and database availabilitys
        int result = backendExchangeCoupon(rest_name, value, num, users[msg.sender].unusedCredits);
        if (result >= 0){
            // mark credits to be used
            users[msg.sender].unusedCredits -= result;
            users[msg.sender].usedCredits += result;
            return 'XXXXXXXX';
        }
        else{
            return '';
        }
    }

    // Authenticator functions (connected with Oracle)
    function authenticate(string memory receiptNo, string memory rest_name) private returns (bool){
        return true;
    }
    
    /**
    * Functions (off-chain simulator)
    **/
    
    function calculateForNewReview(address author) private returns (int credit){
        int author_credit = users[author].unusedCredits + users[author].usedCredits;
        return author_credit / 10;
    }
    
    function calculateForNewComment(bool positive, address author, address commentor) private returns (int creditForAuthor, int creditForCommentor){
        return (5, 5);
    }
    
    // if succeed, return the number of credit exchanged 
    function backendExchangeCoupon(string memory rest_name, uint value, int num, int credits) private returns (int){
        return 0;
    }
    
    function backendSearchReview(string memory rest_name) private returns (Review[] memory reviews){
        return reviews;
    }
    
    function check_available_coupons(address user) private returns (CouponType[] memory available_coupons){
        return couponTypes;
    }

}   