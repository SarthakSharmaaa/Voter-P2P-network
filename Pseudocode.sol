pragma solidity ^0.8.0;

contract FactVoting{

    // The following is a struct defining a voter's userID, trust is the particular domain as mentioned in the report, his coins,
    // if he is eligible as a candidate or not, a map storing the trust array of others and a vote variable for voting.
    struct Voter {
        address userID;
        uint[3] trust;
        uint coins;
        bool candidate;
        mapping(address => uint[3]) trust_of_others;
        uint vote;
        address voteforleader;
    }

    // The below are 2 datastructures used in the below functions, one is a network array of voters and other is a mapping of userID
    // to the voter struct
    Voter[] public network;
    mapping(address => Voter) public voters;

    // Below are some events which occur in the functions below, each explained in their functions each

    event NewsBroadcast(address reciever, string news, uint domain);
    event LeaderElected(address leader);
    event TrustShared(address sender, address recipient);
    event FinalResult(uint result);
    event CandidatesSelected(address leader1, address leader2);
    event RandomInfoSent(address sender,address reciever, string news, uint domain);

    //This is the constructor of the contract calling the voterInitialize function. 
    constructor() public{
         voterInitialize();
    }

    // This function initialize the voters, currently took 9 voters, each having a random userID, trust in domains from 50 to 100
    // Coins also as 50 to 100, and vote/ voteforleaderinitially as -1, They are later pushed into the network array.
    function voterInitialize() private {
        for (uint j = 0; j < 9; j++) {
            uint[3] memory tempTrust;
            address tempAddress;
            uint tempCoins;
            
            for (uint i = 0; i < 3; i++) {
                tempTrust[i] = uint(keccak256(abi.encodePacked(block.timestamp, i))) % 51 +50; 
            }
            tempAddress = address(uint160(uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)))));
            tempCoins = uint(keccak256(abi.encodePacked(block.timestamp))) % 51 +50;
            Voter memory newVoter = Voter(tempAddress, tempTrust, tempCoins, false,-1,-1);
            
            newVoter.trust_of_others[tempAddress] = tempTrust;
            network.push(newVoter);
        }
    }

    // This is a very similar function to initialize a new user in the network, but this time the trust array is set to [0,0,0]
    // And coins as between 0 and 100

    function registerNewUser() public{
        uint[3] memory tempTrust;
        address tempAddress;
        uint tempCoins;
        for (uint i = 0; i < 3; i++) {
                tempTrust[i] = 0; 
            }
            tempAddress = address(uint160(uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)))));
            tempCoins = uint(keccak256(abi.encodePacked(block.timestamp))) % 101;
            Voter memory newVoter = Voter(tempAddress, tempTrust, tempCoins, false,-1);
            
            newVoter.trust_of_others[tempAddress] = tempTrust;
            network.push(newVoter);
    }
    // These are the variables saving userID of leader and an array to save the possible candidates.
    address public leader;
    address[] public possibleCandidates;

    // This function is used to add possible candidates into the possible candidates array
    function addCandidateTopossibleCandidates(address candidateAddress, uint[3] memory totaltrust) public {
        require(!voters[candidateAddress].isCandidate, "Candidate already exists");

        require(totalTrust > 200, "Total trust must be greater than 200");

        voters[candidateAddress].isCandidate = true;
        possibleCandidates.push(candidateAddress);
    }
    // This function is used to add all the possible candidates whose total trust is greater than 200 
    function addpossiblecandidates();() public {
        for (uint i = 0; i < network.length; i++) {
            Voter memory voter = network[i];
            uint totalTrust = voter.trust[0] + voter.trust[1] + voter.trust[2];
            
            if (totalTrust > 200 && !voter.isCandidate) {
                addCandidateToPossibleCandidates(voter.userID, voter.trust, voter.coins);
            }
        }
    }

    // This function is used to elect the leaders with the 2 highest trust and then an event is emmited stating
    // the possible 2 candidates
    function finalCandidatesSelection() public {
        require(possibleCandidates.length >= 2, "Insufficient candidates for leader election");

        address[2] memory leaders;
        uint[2] memory highestTrusts;
        
        for (uint i = 0; i < possibleCandidates.length; i++) {
            address candidateAddress = possibleCandidates[i];
            uint totalTrust = voters[candidateAddress].trust[0] + voters[candidateAddress].trust[1] + voters[candidateAddress].trust[2];

            if (totalTrust > highestTrusts[0]) {
                highestTrusts[1] = highestTrusts[0];
                leaders[1] = leaders[0];
                highestTrusts[0] = totalTrust;
                leaders[0] = candidateAddress;
            } else if (totalTrust > highestTrusts[1]) {
                highestTrusts[1] = totalTrust;
                leaders[1] = candidateAddress;
            }
        }

        emit CandidatesSelected(leaders[0], leaders[1]);
    }

    // This function is used by other voters to vote for the possible candidates 
    function voteToLeader(address candidateAddress) public {
        require(isCandidate(candidateAddress), "Invalid candidate address");
        require(!hasVoted[msg.sender], "You have already voted");

        network[_getVoterIndex(msg.sender)].vote = candidateAddress;
        hasVoted[msg.sender] = true;
        totalVotes++;

        if (totalVotes == network.length) {
            decideLeader();
        }
    }

    // This is a utility function used to count the total votes by the candidates. 
    function countVotesForCandidate(address candidateAddress) internal view returns (uint) {
        uint voteCount = 0;
        for (uint i = 0; i < network.length; i++) {
            if (network[i].vote == candidateAddress) {
                voteCount++;
            }
        }
        return voteCount;
    }

    //THis function is used to decide the leader by counting the possible votes for each candidates and select the 
    // leader
    function decideLeader() internal {
        require(possibleCandidate.length == 2, "Wrong number of candidates for leader election");

        address[2] memory leaders;
        uint[2] memory voteCounts;

        for (uint i = 0; i < possibleCandidate.length; i++) {
            address candidateAddress = possibleCandidate[i];
            uint candidateIndex = i % 2;

            voteCounts[candidateIndex] += countVotesForCandidate(candidateAddress);
            leaders[candidateIndex] = candidateAddress;
        }

        address leader;
        if (voteCounts[0] > voteCounts[1]) {
            leader = leaders[0];
        } else{
            leader=leaders[1];
        }
        emit LeaderElected(leader);
    }

    //This function is used to send news by the fact checker to atleast 1/3rd +1 of the voters
    function sendNewsbyfactchecker() public {
        string memory news="news";
        uint domain = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 3;

        uint numVotersToSend = network.length / 3 + 1;
        for (uint i = 0; i < numVotersToSend; i++) {
            uint index = uint(keccak256(abi.encodePacked(block.timestamp, i))) % network.length;
            address reciever = network[index].userID;
            emit NewsBroadcast(msg.sender, reciever, news, domain);
        }
    }
    // This function is used to send the news by atleast 1 honest voter to the leader
    function honestsendsleader(address honestVoter, string news, uint domain){
        emit Newsbroadcast(honestVoter, leader, news, domain);
    }
     // This function is used to broadcast news and it's domain among the voters by the leader
    function recieveNews(string memory news, uint domain) public {
        for (uint i = 0; i < network.length; i++) {
            emit NewsBroadcast(network[i].userID, message, domain);
        }
    }   

    // This function is used to broadcast the arrays and store the trust arrays of each other by the voters in the network.
    function shareTrustArrays() public {
        for (uint i = 0; i < network.length; i++) {
            for (uint j = 0; j < network.length; j++) {
                if (i != j) {
                    shareTrust(network[i].userID, network[j].trust);
                }
            }
        }
    }

    // This is a utility function helping the above function to share trust arrays of voters with each other
    function shareTrust(address recipient, uint[3] memory trust) public {
        require(recipient != msg.sender, "Cannot share trust with yourself");
        network[_getVoterIndex(recipient)].trust_of_others[msg.sender] = trust;
        emit TrustShared(msg.sender, recipient);
    }

    // This is the function used by the leader to compute the final result it is done as a weighted average as stated 
    // in the report, and finally when the news is fake or true, we call the functions that update the trust and coins
    //of the voters.
    function computeResult(uint domain) public {
        require(electionInProgress, "Leader election is not in progress");

        uint fakeVotes = 0;
        uint trueVotes = 0;

        for (uint i = 0; i < network.length; i++) {
            uint trustLevel = network[i].trust[domain];

            uint weight;
            if (trustLevel >= 0 && trustLevel < 25) {
                weight = 0;
            } 
            else if (trustLevel >= 25 && trustLevel < 50) {
                weight = 1;
            } 
            else if (trustLevel >= 50 && trustLevel < 75) {
                weight = 2;
            } 
            else {
                weight = 3;
            }

            if (network[i].vote == 0) {
                fakeVotes += weight;
            } else {
                trueVotes += weight;
            }
        }
        uint finalResult;
        if (fakeVotes > trueVotes) {
            finalResult = 0; 
        } else if (trueVotes > fakeVotes) {
            finalResult = 1; 
        } else {
            finalResult = 2; 
        }

        electionInProgress = false;

        emit FinalResult(finalResult);
        for (uint j = 0; j < network.length; j++) {
            if (network[j].vote == finalResult) {
                _updateTrust(network[j].userID, domain, true);
                _updateCoins(network[j].userID, true);
            } else {
                _updateTrust(network[j].userID, domain, false);
                _updateCoins(network[j].userID, false);
            }
        }
    }

    // This function is used to update trust after the results are computed of every voter by every voter
    // in their trustofother dictionary.
    function _updateTrust(address voterAddress, uint domain, bool isTrueVote) private {
            uint index = _getVoterIndex(voterAddress);
            
            uint currentTrust = network[index].trust[domain];
            
            if (isTrueVote) {
                if (currentTrust + 5 <= 99) {
                    network[index].trust[domain] += 5;
                }
                else{
                    network[index].trust[domain] = 0;
                }
            } else {
                if (currentTrust >= 5) {
                    network[index].trust[domain] -= 5;
                } else {
                    network[index].trust[domain] = 0;
                }
            }
        }    

    // This function is used to update coins after the results are computed of every voter in their coins amount
    function _updateCoins(address voterAddress, bool isTrueVote) private {
        uint index = _getVoterIndex(voterAddress);
        uint currentCoins = network[index].coins;
        if (isTrueVote) {
            if (currentCoins + 5 <= 99) {
                network[index].coins += 5;
            }
            else{
                network[index].coins =99;
            }
        } else {
            if (currentCoins >= 5) {
                network[index].coins -= 5;
            } else {
                network[index].coins = 0;
            }
        }
    }

    // This is a utility function to get the voterIndex of every user used by the above functions.
    function _getVoterIndex(address voterAddress) private view returns (uint) {
        for (uint i = 0; i < network.length; i++) {
            if (network[i].userID == voterAddress) {
                return i;
            }
        }
        revert("Voter not found in the network");
    }
}

// Thank You
