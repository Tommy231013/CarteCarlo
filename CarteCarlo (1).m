function CarteCarlo()

    NUM_SIMS = 10000;

    fprintf('\n===== CARTE CARLO =====\n');
    fprintf('Card format: rank + suit (e.g. Ah = Ace of hearts, Td = Ten of diamonds)\n');
    fprintf('Ranks: A 2 3 4 5 6 7 8 9 T J Q K\n');
    fprintf('Suits: h=hearts  d=diamonds  c=clubs  s=spades\n\n');

    c1 = input('Your first card: ', 's');
    c2 = input('Your second card: ', 's');
    playerHand = [parseCard(c1), parseCard(c2)];

    deck = 1:52;
    deck = deck(~ismember(deck, playerHand));

    community = [];

    fprintf('\n-- PRE-FLOP --\n');
    [pWin, oWin, tie, handProbs, runHist] = simulate(playerHand, community, deck, NUM_SIMS);
    printResults(pWin, oWin, tie, handProbs);
    plotConvergence(runHist, 'Pre-Flop');

    fprintf('\nEnter the 3 flop cards:\n');
    f1 = input('Flop card 1: ', 's');
    f2 = input('Flop card 2: ', 's');
    f3 = input('Flop card 3: ', 's');
    community = [parseCard(f1), parseCard(f2), parseCard(f3)];
    deck = deck(~ismember(deck, community));

    fprintf('\n-- FLOP --\n');
    [pWin, oWin, tie, handProbs, runHist] = simulate(playerHand, community, deck, NUM_SIMS);
    printResults(pWin, oWin, tie, handProbs);
    plotConvergence(runHist, 'Flop');

    t1 = input('\nTurn card: ', 's');
    community = [community, parseCard(t1)];
    deck = deck(~ismember(deck, community));

    fprintf('\n-- TURN --\n');
    [pWin, oWin, tie, handProbs, runHist] = simulate(playerHand, community, deck, NUM_SIMS);
    printResults(pWin, oWin, tie, handProbs);
    plotConvergence(runHist, 'Turn');

    r1 = input('\nRiver card: ', 's');
    community = [community, parseCard(r1)];

    fprintf('\n-- RIVER --\n');
    [pWin, oWin, tie, handProbs, runHist] = simulate(playerHand, community, deck, NUM_SIMS);
    printResults(pWin, oWin, tie, handProbs);
    plotConvergence(runHist, 'River');

    fprintf('\n=======================\n');

end


function [pWin, oWin, tie, handProbs, runningWinPct] = simulate(playerHand, community, remainingDeck, numSims)
    winsP = 0; winsO = 0; ties = 0;
    handCounts = zeros(1, 10);  
    cardsNeeded = 5 - length(community);
    runningWinPct = zeros(1, numSims);  

    for i = 1:numSims
        shuffled = remainingDeck(randperm(length(remainingDeck)));

        oppHand = shuffled(1:2);
        boardCards = shuffled(3 : 2 + cardsNeeded);
        board = [community, boardCards];

        [scoreP, catP] = bestHandScore([playerHand, board]);
        [scoreO, ~]    = bestHandScore([oppHand,    board]);

        if scoreP > scoreO
            winsP = winsP + 1;
        elseif scoreO > scoreP
            winsO = winsO + 1;
        else
            ties = ties + 1;
        end

        handCounts(catP + 1) = handCounts(catP + 1) + 1;

        runningWinPct(i) = winsP / i * 100;
    end

    pWin      = winsP / numSims * 100;
    oWin      = winsO / numSims * 100;
    tie       = ties  / numSims * 100;
    handProbs = handCounts / numSims * 100;
end


function plotConvergence(runningWinPct, streetLabel)

    numSims = length(runningWinPct);

    figure('Name', ['Convergence - ' streetLabel]);
    semilogx(1:numSims, runningWinPct, 'LineWidth', 1.5); % Log scale to see the stabilisation 
    hold on;
    yline(runningWinPct(end), '--r', 'Final value');
    xlabel('Number of Simulations Completed So Far (log scale)');
    ylabel('Running Win Probability (%)');
    title(['Monte Carlo Convergence - ' streetLabel]);
    grid on;

end


function [score, category] = bestHandScore(cards)
    combos = nchoosek(1:length(cards), 5);
    score = 0; category = 0;
    for i = 1:size(combos, 1)
        [s, c] = handScore(cards(combos(i,:)));
        if s > score
            score = s;
            category = c;
        end
    end
end

function [score, category] = handScore(hand)
    ranks = mod(hand - 1, 13) + 1;
    suits = floor((hand - 1) / 13);

    ranks(ranks == 1) = 14;  % Ace high
    ranks = sort(ranks, 'descend');

    isFlush    = (length(unique(suits)) == 1);
    isStraight = isStraightCheck(ranks);

    counts = histc(ranks, unique(ranks));  
    counts = sort(counts, 'descend');

    if isFlush && isStraight && ranks(1) == 14 && ranks(2) == 13
        category = 9;   % Royal flush
    elseif isFlush && isStraight
        category = 8;   % Straight flush
    elseif counts(1) == 4
        category = 7;   % Four of a kind
    elseif counts(1) == 3 && counts(2) == 2
        category = 6;   % Full house
    elseif isFlush
        category = 5;   % Flush
    elseif isStraight
        category = 4;   % Straight
    elseif counts(1) == 3
        category = 3;   % Three of a kind
    elseif counts(1) == 2 && counts(2) == 2
        category = 2;   % Two pair
    elseif counts(1) == 2
        category = 1;   % One pair
    else
        category = 0;   % High card
    end

    score = category * 1e10 + ranks(1)*1e8 + ranks(2)*1e6 + ranks(3)*1e4 + ranks(4)*1e2 + ranks(5);
end



function result = isStraightCheck(sortedRanks)
    result = (sortedRanks(1) - sortedRanks(5) == 4) && (length(unique(sortedRanks)) == 5);
    if isequal(sort(sortedRanks), [2 3 4 5 14]) % Special case (Straight Wheel)
        result = true;
    end
end


function printResults(pWin, oWin, tie, handProbs)
    handNames = {'High Card', 'One Pair', 'Two Pair', 'Three of a Kind', ...
                 'Straight', 'Flush', 'Full House', 'Four of a Kind', ...
                 'Straight Flush', 'Royal Flush'};

    fprintf('  You:      %.1f%%\n', pWin);
    fprintf('  Opponent: %.1f%%\n', oWin);
    fprintf('  Tie:      %.1f%%\n\n', tie);

    fprintf('  Your hand probabilities:\n');
    for i = 1:10
        if handProbs(i) > 0.5  % only show hands with >0.5% chance
            fprintf('    %-20s %.1f%%\n', handNames{i}, handProbs(i));
        end
    end

    if pWin >= 65
        action = 'RAISE';
    elseif pWin >= 45
        action = 'CALL / CHECK';
    else
        action = 'FOLD';
    end
    fprintf('\n  >> Recommendation: %s\n', action);
end


function card = parseCard(str)
    str = upper(strtrim(str));
    rankChars = 'A23456789TJQK';
    suitChars = 'CDHS';

    r = strfind(rankChars, str(1));
    s = strfind(suitChars, str(2));

    if isempty(r) || isempty(s)
        error('Invalid card: %s. Use format like Ah, Td, Ks', str);
    end

    card = (s - 1) * 13 + r;
end