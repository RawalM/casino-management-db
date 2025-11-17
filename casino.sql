-- QUESTION 1
-- Creating Table PLayers to store the details of the players
create TABLE Players (
birth_day DATE,				-- PLayer Birth Date
first_name varchar(20),		-- PLayer First Name
last_name VARCHAR(20),		-- PLayer Last Name
is_dealer BOOL,				-- Dealer Yes/No
g_id INT PRIMARY KEY		-- Player ID: Primary Key
);


-- Creating Table Hands to stote the details of each game the player participates in 
create TABLE Hands(
time DATETIME,				-- Time the game was played
game_type VARCHAR(20),		-- Name of game played
g_id INT,					-- Player ID :: Foreign Key from Table Players
r_id INT,					-- Round ID for the round number
h_id INT PRIMARY KEY,       -- Unique ID for each hand that is played
FOREIGN KEY (g_id) REFERENCES Players(g_id)   -- Foreign Key Statement
);


-- Creating table Cards to hold card details for each hand 
create TABLE Cards(
rnk INT,					-- Rank of the card
suit VARCHAR(20),			-- Suit of the card liek spades, hearts, etc
h_id INT,					-- Unique ID for each hand played :: Foreign key from table Hands
FOREIGN KEY (h_id) REFERENCES Hands(h_id)   -- Foreign Key Statement
);


-- Creating Table Bets to keep a record of all the bets in each hand 
create TABLE Bets(
amount INT,					-- Amount Bet 
h_id INT,					-- Unique ID for each hand played :: Foreign key from table Hands
FOREIGN KEY (h_id) REFERENCES Hands(h_id)	-- Foreign Key Statement
);



-- QUESTION 2
-- Creating a queery to sum up the bets that are places in the month of October 2024
CREATE VIEW October2024Bets As
select sum(amount) AS total_bets from Bets
Join Hands on Bets.h_id = Hands.h_id 
Where month(time) = 10 AND Year(time) = 2024;


-- QUESTION 3
-- Creating a query to check if each player playing the games is above 20 years of age
Create VIEW Above20 As
Select Hands.h_id, Players.first_name, Players.last_name,
	CASE 
		WHEN datediff(Hands.time, Players.birth_day) >= 7305 then 1 else 0
	End as Above20
From Hands 
join Players on Hands.g_id = Players.g_id
Order by Hands.h_id;


-- QUESTION 4
-- Creating a querry to view all the people who have their birthdays after 6 November 
Create VIEW UpcomingBirthdays As
Select birth_day,first_name,last_name FROM Players
Order By
	Case
		When Month(birth_day) > 11 or (Month(birth_day)=11 AND DAY(birth_day)>=6) THEN 1 ELSE 2
    End,
    Month(birth_day),Day(birth_day);
    

-- QUESTION 5
-- Creating a querry to calculate hand value for blackjack games with hand id numbers at most 5 
-- bust i.e over 21 shoulld be given value as 0
-- hand ID <= 5
Create VIEW SimpleBlackJack AS
Select Cards.h_id,
	Case
		WHEN SUM(Cards.rnk) >= 22 THEN 0 ELSE SUM(Cards.rnk)
	End as Hand_value
From Cards
Join Hands on Cards.h_id= Hands.h_id Where Hands.game_type = 'Blackjack' And Cards.h_id<=5
Group by Cards.h_id
Order by Cards.h_id;


-- QUESTION 6
-- We can proceed like wee did above calculate hand values and manage face cards and aces 
-- face cards ki value 10
-- Uske baad aces ki value ko adjust kar lenge taki check kar paye ki bust hai ki nahi 
-- Uske baad maximum value of each hand check karenge and phir winner decide ho jayega 
-- isme ham saare cards ki values ko manage kar rahe hai 
-- Figuring out which is the aximum hand value every round

-- Fixing value of any face card to 10 
CREATE VIEW FixValueToCard AS 
SELECT Cards.h_id,
CASE
    WHEN Cards.rnk > 10 THEN 10 ELSE Cards.rnk
END AS CardValue
From Cards;

-- Calculating the initial vallue of hand and checking if there is any ace present or not
CREATE VIEW InitialHandCalculation AS
SELECT Hands.h_id, Hands.r_id,
CASE
    WHEN SUM(FixValueToCard.CardValue) >= 22 THEN 0 ELSE SUM(FixValueToCard.CardValue)
END AS ValueHand,
CASE
    WHEN SUM(CASE WHEN FixValueToCard.CardValue = 1 THEN 1 ELSE 0 END) > 0 THEN true ELSE false
END AS AcePresentOrNot
FROM Hands NATURAL JOIN FixValueToCard GROUP By Hands.h_id, Hands.r_id;

-- if value is less than 10 ace is considered to be 11 otherwise as 1
CREATE VIEW RevisingCalculationIfAcePresent AS
SELECT InitialHandCalculation.h_id, InitialHandCalculation.r_id,
CASE
    WHEN AcePresentOrNot AND ValueHand < 12 THEN ValueHand + 10 ELSE ValueHand
END AS ValueHand
FROM InitialHandCalculation;

CREATE VIEW MaxHandPerRound AS
SELECT Hands.r_id, Hands.g_id FROM RevisingCalculationIfAcePresent NATURAL JOIN Hands
WHERE 
    ValueHand = (SELECT MAX(ValueHand) FROM RevisingCalculationIfAcePresent NATURAL JOIN Hands AS final WHERE final.r_id = Hands.r_id) AND Hands.game_type = 'Blackjack'
GROUP BY Hands.r_id, Hands.g_id;


-- Trying to figure out if the top hand in each rounf belongs to a dealer or not 
CREATE VIEW Blackjack AS SELECT MaxHandPerRound.r_id, 
CASE 
    WHEN Players.is_dealer THEN 0 ELSE 1 
END AS Outsider_wins
FROM MaxHandPerRound NATURAL JOIN Players;
