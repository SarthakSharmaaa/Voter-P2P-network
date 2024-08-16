import random
import string
import statistics
import matplotlib.pyplot as plt

# This is the class to initialize the voter similar to the one in the pseudocode.sol
class Voter:
    def __init__(self):
        self.userID = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
        self.trust = [random.randint(50, 99) for _ in range(3)]
        self.coins = random.randint(50, 99)
        self.honesty=None
        self.trust_of_others = {}
   
# This is the function to initialize voter objects according to the value of n, p and q     
def initialize(n,p,q):
    voters=[]
    for i in range(n):
        voter=Voter()
        voters.append(voter)
    malicious=int(n*q)
    print(malicious)
    honest=n-malicious
    trustworthy=int(honest*p)
    lesstrusted=honest-trustworthy
    x=0
    for i in range(malicious):
        voters[x].honesty=0
        x+=1
    for i in range(trustworthy):
        voters[x].honesty=1
        x+=1
    for i in range(lesstrusted):
        voters[x].honesty=2
        x+=1
    trustshare(voters)
    return voters

#This function is used to simulate the voting and it returns the array of the accuracy of each news passed
# It implements the weighted voting and according to the value of p and q calculates voting
def simulate_voting(voters, news):
    voting_result_accuracy=[]
    for i in range(news):
        correct_votes=0
        correct_voters=[]
        wrong_votes=0
        wrong_voters=[]
        for voter in voters:
            trust_range = voter.trust[0]
            if trust_range < 25:
                weight = 0
            elif trust_range < 50:
                weight = 1
            elif trust_range < 75:
                weight = 2
            else:
                weight = 3
            if voter.honesty == 0:
                wrong_votes+=weight
                wrong_voters.append(voter)
            elif voter.honesty == 1:
                correct_probabilty=random.random()
                #print(correct_probabilty)
                if correct_probabilty<0.9:
                    correct_votes+=weight
                    correct_voters.append(voter)
                else:
                    wrong_votes+=weight
                    wrong_voters.append(voter)
            else:  
                correct_probabilty=random.random()
                if correct_probabilty<0.7:
                    correct_votes+=weight
                    correct_voters.append(voter)
                else:
                    wrong_votes+=weight
                    wrong_voters.append(voter)
        if correct_votes>wrong_votes:
            increment_trust_and_coins(correct_voters)
            decrement_trust_and_coins(wrong_voters)
        else:
            increment_trust_and_coins(wrong_voters)
            decrement_trust_and_coins(correct_voters)
        total_votes=correct_votes+wrong_votes
        #print(correct_votes)
        #print(wrong_votes)
        accuracy=correct_votes/total_votes
        voting_result_accuracy.append(accuracy)
    return voting_result_accuracy

#If a voter gives right vote and he wins the voting then his trust and coins is increased in that particular domain
#the trust_of_others is also updated accordingly, This function is called in simulate_voting
        
def increment_trust_and_coins(voters):
    for voter in voters:
        voter.trust[0] = min(99, voter.trust[0] + 5) 
        voter.coins+=5 
        for other_voter in voters:
            other_voter.trust_of_others[voter.userID] = voter.trust
#If a voter gives wrong vote and he loses the voting then his trust and coins is decreased in that particular domain
#the trust_of_others is also updated accordingly, This function is called in simulate_voting
def decrement_trust_and_coins(voters):
    for voter in voters:
        voter.trust[0] = max(0, voter.trust[0] - 5)
        voter.coins = max(0, voter.coins - 5)
        for other_voter in voters:
            other_voter.trust_of_others[voter.userID] = voter.trust


# This function is used to share the trust_of_other dictionary with each other during initialization.           

def trustshare(voters):
    dictator = {voter.userID: voter.trust for voter in voters}
    for i in range(len(voters)):
        voters[i].trust_of_others = dictator

#This function is used to implement the accuracy vs number of voters graph

# N_values = [10, 20, 50, 100, 200, 500, 1000]  
# P = 0.8
# Q = 0.25
# NUM_NEWS_ITEMS = 10

# accuracies = []

# for N in N_values:
#     voters = initialize(N, P, Q)
#     news_accuracies = simulate_voting(voters, NUM_NEWS_ITEMS)
#     avg_accuracy = sum(news_accuracies) / len(news_accuracies)
#     accuracies.append(avg_accuracy)

# plt.plot(N_values, accuracies, marker='o')
# plt.title('Accuracy vs. Number of Voters')
# plt.xlabel('Number of Voters (N)')
# plt.ylabel('Average Accuracy')
# plt.grid(True)
# plt.savefig("accuracyvsvoters.png")

#This function is used to implement the accuracy vs trustworthiness ratio p graph

# N = 100  
# Q = 0.25    
# NUM_NEWS_ITEMS = 10

# P_values = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]

# accuracies = []

# for P in P_values:
#     voters = initialize(N, P, Q)
#     news_accuracies = simulate_voting(voters, NUM_NEWS_ITEMS)
#     avg_accuracy = sum(news_accuracies) / len(news_accuracies)
#     accuracies.append(avg_accuracy)

# plt.plot(P_values, accuracies, marker='o')
# plt.title('Accuracy vs. Trustworthiness (P)')
# plt.xlabel('Trustworthiness (P)')
# plt.ylabel('Average Accuracy')
# plt.grid(True)

# plt.savefig("accuracyvsp.png")

#This function is used to implement the accuracy vs number of malicious voters ratio q.

N = 100 
P = 0.8
NUM_NEWS_ITEMS = 10

Q_values = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]

accuracies = []

for Q in Q_values:
    voters = initialize(N, P, Q)
    news_accuracies = simulate_voting(voters, NUM_NEWS_ITEMS)
    avg_accuracy = sum(news_accuracies) / len(news_accuracies)
    accuracies.append(avg_accuracy)

plt.plot(Q_values, accuracies, marker='o')
plt.title('Accuracy vs. Maliciousness (Q)')
plt.xlabel('Maliciousness (Q)')
plt.ylabel('Average Accuracy')
plt.grid(True)

plt.savefig("accuracyvsq.png")

#Thank You
    
        