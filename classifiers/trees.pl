:-use_module(library(clpfd)).

%data(P,pos),data(N,neg),features(FF),tree(FF,P,N,Tree), write(Tree).


features(F):-
	F=[length,gills,beak,teeth].
data(D,pos):-
	D =[[3,no,yes,many],
	    [4,no,yes,many],
	    [3,no,yes,few],
	    [5,no,yes,many],
	    [5,no,yes,few]].
data(D,neg):-
	D =[[5,yes,yes,many],
	   [4,yes,yes,many],
	   [5,yes,no,many],
	   [4,yes,no,many],
	   [4,no,yes,few]].


bdivide(Y,X,Z):-
	Z is X/Y.

multiply(X,Y,Z):-
	Z is X*Y.

%f is a feature index
pos_neg_f_entropy(P,N,F,E):-
	append(P,N,AllData),
	maplist(nth1(F),P,PValues),
	maplist(nth1(F),N,NValues),
	append(PValues,NValues,AllValues),
	list_to_set(AllValues,UValues),
	maplist(list_value_count(PValues),UValues,PCounts),
	maplist(list_value_count(NValues),UValues,NCounts),
	maplist(entropy,PCounts,NCounts,Ents),
        maplist(plus,PCounts,NCounts,TotalCounts),
	length(AllData,DataSize),
	maplist(bdivide(DataSize),TotalCounts,TotalDivs),
	maplist(multiply,TotalDivs,Ents,WeightedEnts),
	sumlist(WeightedEnts,E).


list_value_count(List,Value,Count):-
	Count=0,
	maplist(dif(Value),List).
list_value_count(List,Value,Count):-
	aggregate(count,(member(Value,List)),Count).



log2(X,Log2):-
	Log2 is log(X)/log(2).

entropy(0,_,0).
entropy(_,0,0).
entropy(X,Y,E):-
	dif(X,0),
	dif(Y,0),
	plus(X,Y,Sum),
	ProX is X/Sum,
	log2(ProX,LogProX),
	ProY is Y/Sum,
	log2(ProY,LogProY),
	E is -(ProX*LogProX)-(ProY*LogProY).


pos_neg_es(P,N,F,PairEs):-
	length(F,NF),
	numlist(1,NF,NL),
	maplist(pos_neg_f_entropy(P,N),NL,Es),
	pairs_keys_values(PairEs,F,Es).


matrix_colIndex_col(M,C,S):-
	maplist(nth1(C),M,S).

matrix_colindicies_submatrix(M,Cs,S2):-
	maplist(matrix_colIndex_col(M),Cs,S1),
	transpose(S1,S2).


matrix_notcolindicies_submatrix(Cs,M,S):-
	M=[H|_],
	length(H,L),
	numlist(1,L,NL),
	subtract(NL,Cs,ColsToKeep),
	matrix_colindicies_submatrix(M,ColsToKeep,S).

matrix_notcolindicies_submatrix(_,[],[]).


matrix_rowequation_submatrix(F,M,V,Submatrix):-
	findall(Row, (member(Row,M),nth1(F,Row,V)),Submatrix).

pairEs_best(P,YIs-XIs):-
	aggregate(min(X,Y),member(Y-X,P),min(XIs,YIs)).


split_data(P,N,F,Possubs,Nsubs,UValues):-
	maplist(nth1(F),P,PValues),
	maplist(nth1(F),N,NValues),
	append(PValues,NValues,AllValues),
	list_to_set(AllValues,UValues),
	maplist(matrix_rowequation_submatrix(F,P),UValues,Possubs),
	maplist(matrix_rowequation_submatrix(F,N),UValues,Nsubs).

mynth(L,I,E):-
	nth1(I,L,E).
features_indicies(F,I):-
	maplist(mynth(F),I,F).

%learn_tree, %need to put the arc labels in somehow
tree(F,[],Neg,Value,Value-leaf(neg(NL))):- length(Neg,NL).%do leaf.
tree(F,Pos,[],Value,Value-leaf(pos(PL))):-length(Pos,PL). %do leaf.
tree(F,P,N,Value,Value-node(BestV,Trees)):-
	features_indicies(F,Fi),
	pos_neg_es(P,N,Fi,PairEs),
	pairEs_best(PairEs,Best-BValue),
	split_data(P,N,Best,PosSplits,NegSplits,UValues),
	%might be a 3 or 4 ways split..
	nth1(Cs,Fi,Best),%might not need this line
	maplist(matrix_notcolindicies_submatrix([Cs]),PosSplits,PosSplits2),
	maplist(matrix_notcolindicies_submatrix([Cs]),NegSplits,NegSplits2),
        nth1(Best,F,BestV),
	select(BestV,F,F2),
	%need a tree for each split
	maplist(tree(F2),PosSplits2,NegSplits2,UValues,Trees).



tree_example_classification(Tree,Example,Classification).


root-node(gills,
	  [
	      no-node(length,
		   [
		       3-leaf(pos(2)),
		       4-node(teeth,
			      [
				  many-leaf(pos(1)),
				  few-leaf(neg(1))]),
		       5-leaf(pos(2))]),
	      yes-leaf(neg(4))]).
