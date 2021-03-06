################################# Load Data ####################################################################################
library(rstan)
library(rethinking)

setwd("insert path")
 d<-read.csv("Data-A.Lub.Full.csv")
   
 Y<-d[1:51,120:135]
 
 Whites<-d$White
 
 Total<-c()
          GGG<-cbind(d$White, d$Mestizo , d$Mulato, d$Indigenous, d$Black  )
 for(i in 1:51){
 Total[i]<-sum(GGG[i,])
 }
 

################################# Pre-Processing in R ###########################################################################
L<-51
D<-2
K<-16
Y<-Y
S<-8

########################################################################################################## STAN MODEL Data 
model_dat  <-list(S=S,L=L,D=D,K=K,Whites=Whites,Total=Total,Outcome=Y)
    
  
##############################################################################################################STAN MODEL Code  
model_code<-"
########################################################################################################## Data Block 
data {
int<lower=2> K;
int<lower=0> L;
int<lower=1> D;
int<lower=1> S;

int<lower=0> Outcome[L,K];  
int<lower=0> Whites[L];
int<lower=0> Total[L];

}

parameters {
#######
# Theta 
#######
real Theta[L];

#### Regression
vector[D] Beta;
ordered[K-1] C;
}


model {
vector[K] scrap;

Theta~normal(0,10);

# Model District Level for Acars 
for(l in 1:L){
  Whites[l]~binomial(Total[l],inv_logit(Theta[l]));
}

###################### Priors for Regression 
for (d in 1:D){
Beta[d] ~ normal(0,10);} 

##################### Main Regression
# The code used in the model implies the commented out model, but is more effcient computationally
#for (n in 1:N){
#Outcome[n] ~ ordered_logistic((Beta[1] + Beta[2]*inv_logit(Theta[Cluster[n]])  ), C);
#}
for (n in 1:L) {
real eta;
eta <- Beta[1] + Beta[2]*inv_logit(Theta[n]);
scrap[1] <- 1 - inv_logit(eta - C[1]);
for (k in 2:(K-1))
scrap[k] <- inv_logit(eta - C[k-1]) - inv_logit(eta - C[k]);
scrap[K] <- inv_logit(eta - C[K-1]);
Outcome[n] ~ multinomial(scrap);

}
}"


################################################################################ Fit the Model IN STAN!
fitParasitesWhitesEdu<- stan(model_code=model_code, data = model_dat,inits=0, iter = 4000, warmup=2000,chains = 1)

  print(fitParasitesWhitesEdu,digits_summary=3)
  traceplot(fitParasitesWhitesEdu,ask=T,pars=c("Theta","C","Beta"))
  
  Beta<-extract(fitParasitesWhitesEdu, pars="Beta")$Beta
  C<-extract(fitParasitesWhitesEdu, pars="C")$C
  Theta<-seq(0,1,length.out=21)
 
 library(rethinking)
  Pred<-array(NA, c(2000,(K),21))
 for(i in 1:2000){ 
  for (n in 1:21) {
eta <- Beta[i,1] + Beta[i,2]*logistic(Theta[n]);
scrap<-c()
scrap[1] <- 1 - logistic(eta - C[i,1]);
for (k in 2:(K-1)){
scrap[k] <- logistic(eta - C[i,k-1]) - logistic(eta - C[i,k]);}
scrap[K] <- logistic(eta - C[i,K-1]);

 Pred[i,,n]<-cumsum(scrap)
 }} 
  
  mPred<-matrix(NA,nrow=21,ncol=K)
  
  for(i in 1:21){
  for(j in 1:K){
  mPred[i,j]<-mean(Pred[,j,i])
  }}
  
############ Plot Results
library(Cairo)
CairoPDF(width=8, height=8, "WhiteEducationModel.pdf")

  plot(mPred[,1]~Theta,ylim=c(0,1),type="n",col=rgb(1, 0, 0,alpha=.9),ylab="Cumulative Probability", xlab="Perecentage of Population that is White" )
 
  for(i in 0:(K-2)){
  for(z in 1:200){
  zz<-z*10
  lines(Pred[zz,i+1,]~Theta, col=rgb((1-(i*.06)), 0, ((i*.06)),alpha=.06))}
  }
  
 # for(i in 0:(K-2)){
 # lines(mPred[,i+1]~Theta, col=rgb((1-(i*.06)), 0, ((i*.06)),alpha=.5))
 # }
  
  abline(h=.2)
  abline(h=.4)
  abline(h=.6)
  abline(h=.8)
  abline(h=1)
  abline(h=0)
       
       dev.off()
       


