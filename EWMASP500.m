data = readtable('sp500.xlsx');
sp = data.Close;
dates = data.Date;
Returns = tick2ret(sp);
Returns = Returns(2:end);
dates = datetime(dates, 'InputFormat', 'dd-MM-yyyy');
 
DateReturns = dates(2:end);
SampleSize = length(Returns);
 
TestWindowStart      = find(year(DateReturns)==1992,1);
TestWindow           = TestWindowStart : SampleSize;
EstimationWindowSize = 250;
pVaR = [0.05 0.01];
 
Zscore   = norminv(pVaR);
Normal95 = zeros(length(TestWindow),1);
Normal99 = zeros(length(TestWindow),1);



for t = TestWindow
    i = t - TestWindowStart + 1;
    EstimationWindow = t-EstimationWindowSize:t-1;
    X = Returns(EstimationWindow);
    Historical95(i) = -quantile(X,pVaR(1));
    Historical99(i) = -quantile(X,pVaR(2));
end


Lambda = 0.94;
Sigma2     = zeros(length(Returns),1);
Sigma2(1)  = Returns(1)^2;

for i = 2 : (TestWindowStart-1)
    Sigma2(i) = (1-Lambda) * Returns(i-1)^2 + Lambda * Sigma2(i-1);
end


Zscore = norminv(pVaR);
EWMA95 = zeros(length(TestWindow),1);
EWMA99 = zeros(length(TestWindow),1);

for t = TestWindow
    k     = t - TestWindowStart + 1;
    Sigma2(t) = (1-Lambda) * Returns(t-1)^2 + Lambda * Sigma2(t-1);
    Sigma = sqrt(Sigma2(t));
    EWMA95(k) = -Zscore(1)*Sigma;
    EWMA99(k) = -Zscore(2)*Sigma;
end

figure;
hold on
newcolors = {'#dd820d','#ff0101'};
colororder(newcolors)
plot(DateReturns(TestWindow),EWMA95, DateReturns(TestWindow), EWMA99, 'Linewidth', 1.5)
grid on
ylabel('VaR')
xlabel('Date')
legend({'95% Confidence Level','99% Confidence Level'},'Location','Best')
title('VaR Estimation Using the EWMA Method')

ReturnsTest = Returns(TestWindow);
DatesTest   = DateReturns(TestWindow);
figure;

grid on
hold on
newcolors = {'#6517d1','#dd820d','#ff0101'};
colororder(newcolors)
p = plot(DatesTest, ReturnsTest, DatesTest, -EWMA95, DatesTest, -EWMA99)
p(1).LineWidth = 0.5;
p(2).LineWidth = 1.5;
p(3).LineWidth = 1.5;
hold off
ylabel('VaR')
xlabel('Date')
legend({'Returns','EWMA 95%','EWMA 99%'},'Location','Best')
title('Comparison of returns and VaR at 95% for different models')





ZoomInd   = (DatesTest >= datestr('5-Aug-1998','local')) & (DatesTest <= datestr('31-Oct-1998','local'));
VaRData   = [-EWMA95(ZoomInd) -EWMA99(ZoomInd)];
VaRFormat = {'--','-.'};
D = DatesTest(ZoomInd);
R = ReturnsTest(ZoomInd);
E95 = EWMA95(ZoomInd);
E99 = EWMA99(ZoomInd);
IndE95   = (R < -E95);
IndE99   = (R < -E99);
figure;
s = bar(D,R,0.85,'FaceColor',[0.7216    0.5804    0.8784]);
s.EdgeColor = 'none';
hold on
for i = 1 : size(VaRData,2)
     stairs(D-0.5,VaRData(:,i),VaRFormat{i});
 end
 ylabel('VaR')
 xlabel('Date')
 legend({'Returns','EWMA 95%', 'EWMA 99%'},'Location','Best','AutoUpdate','Off')
 title('95% & 99% confidence VaR exceptions for different models')
 newcolors = {'#021f93','#dd820d','#ff0101','#038385'};
 colororder(newcolors)
 p1 = plot(D(IndE95),-E95(IndE95),'o',D(IndE99),-E99(IndE99),'o','MarkerSize',12)
 p1(1).LineWidth = 1.5;
 p1(2).LineWidth = 1.5;
 xlim([D(1)-1, D(end)+1])
 hold off;


vbt = varbacktest(ReturnsTest,[EWMA95 EWMA99],'PortfolioID','S&P','VaRID',...
    {'EWMA95','EWMA99'},'VaRLevel',[0.95 0.99]);
summary(vbt)
runtests(vbt)


Ind2016 = (year(DatesTest) == 2016);
vbt2016 = varbacktest(ReturnsTest(Ind2016),[EWMA95(Ind2016),EWMA99(Ind2016)],...
   'PortfolioID','S&P, 2016, Jun - Dec','VaRID',{'EWMA 95%','EWMA 99%'},'VaRLevel',[0.95 0.99]);
runtests(vbt2016)

cci(vbt2016)

tbfi(vbt2016)