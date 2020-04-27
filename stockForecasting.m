%Datas for 6 stocks have been saved in excel format in the "Data" directory.
%In this code,user is asked to chose one of those stocks. Then code fetches
%for the corresponding stock from excel file, segments into training and test data
%(50% - 50%). SVM training code is run on the training data and prediction code
%is run on the test data.

clc 
clear all
close all


messageToUser=['Select stock to analyze, enter \n 1 for SBI \n 2 for ITC \n 3 for TataSteel \n' ...
' 4 for ShreeRamaNewsPrint \n 5 for KaruturiGlobal \n 6 for AurobindoPharma \n'];
userInput=input(messageToUser); %Asking user input for selecting stock to analyze

%Choosing appropriate stock name according to user input
switch userInput
    case 1
        stockName='SBI';
    case 2
        stockName='ITC';
    case 3
        stockName='TataSteel';
    case 4
        stockName='ShreeRamaNewsPrint';
    case 5
        stockName='KaruturiGlobal';
    case 6
        stockName='AurobindoPharma';
    otherwise
        error('Entered input is not valid');
end
 
%Reading the stock data from excel file
stockData=xlsread(strcat('.\Data\',stockName,'\modified.xlsx'));
stockData=flipud(stockData); %In excel file data goes from recent date at top
%to oldest data at bottom. So it has been flipped

modifiedStockData=stockData(stockData(:,5)~=0,:);
%modified data is data excluding those days where volume of traded stock is
%0, i.e. a national holiday

sizeModifiedData=size(modifiedStockData);



%Converting Stock Data according to change per day data
stockDataChangePerDay=zeros(sizeModifiedData(1)-1,sizeModifiedData(2));
for iter1=2:sizeModifiedData(1)
    for iter2=1:sizeModifiedData(2)
    stockDataChangePerDay((iter1-1),iter2)=(modifiedStockData(iter1,iter2)-modifiedStockData(iter1-1,iter2))/(modifiedStockData(iter1-1,iter2));
    end
end

%Creating output feature (open price of the day - closing price of the
%previous day)
outputFeature=zeros(sizeModifiedData(1)-1,1);
for iter=2:sizeModifiedData(1)
    outputFeature((iter-1),1)=(modifiedStockData(iter,1)-modifiedStockData(iter-1,4))/(modifiedStockData(iter-1,4));
end 

%COnverting output fetures to discrete values
outputFeature(outputFeature>0)=1;
outputFeature(outputFeature<=0)=0;


sizeData=size(stockDataChangePerDay);

trainingSizeIndex=0.5;
sizeTrainingData=floor(trainingSizeIndex*sizeData(1));

%Segmenting the data into training and test data
trainingData=stockDataChangePerDay(1:sizeTrainingData,:);
testData=stockDataChangePerDay((sizeTrainingData+1):end,:);


%Normalizing the training data (deriving normalization factor from training data)
%Also normalizing test data by the same normalization factors
for iter=1:sizeData(2)
    maxData=max(trainingData(:,iter));
    minData=min(trainingData(:,iter));
    trainingData(:,iter)=(trainingData(:,iter)-minData)/(maxData-minData);
    testData(:,iter)=(testData(:,iter)-minData)/(maxData-minData);
end

%Adding SVM directory. Precompiled LibSVM has been used here
addpath('.\Libsvm\');

cValue=1;  %Parameter for SVM
gValue=1;  %Parameter for SVM
cStrVal=num2str(cValue);
gStrVal=num2str(gValue);
stringis=['-s 0 -t 2 -c ',cStrVal,' -g ',gStrVal];
%SVM Training Phase
svmTrainedStruct=svmtrain2(outputFeature(1:sizeTrainingData,1),trainingData,stringis);
%SVM Prediction Phase
predictedClass=svmpredict(outputFeature(sizeTrainingData+1:end,1),testData,svmTrainedStruct);
%Checking accuracy of predicted data 
result=(predictedClass==outputFeature(sizeTrainingData+1:end,1));
resultIndex=(sum(result==1)/length(result))*100;

disp(strcat({'Accuracy for prediction for stock '},stockName,{' is '},num2str(resultIndex),'%'));
     

