<h1>Predicting Customer Satisfaction in E-Commerce</h1>

 ### [View Full Report](https://github.com/jcastro712/CustomerSatisfaction/blob/main/Predicting%20Customer%20Satisfaction%20Short%20Version.pdf)

 ### [View R Code](https://github.com/jcastro712/CustomerSatisfaction/blob/main/Final%20Project%20Code.R)

<h2>Description</h2>
This project uses machine learning in R to predict whether a customer will leave a positive review (4-5 stars) or a negative review (1-3 stars) on Olist, a Brazilian e-commerce marketplace. Six raw Olist datasets (customers, orders, order items, payments, reviews, and products) are cleaned and merged into a single modeling table of over 100,000 orders, then used to train and compare three classifiers: Logistic Regression, Random Forest, and XGBoost.
<br />

<h2>Languages and Utilities Used</h2>

- <b>R</b>
- <b>tidyverse</b> (data cleaning and wrangling)
- <b>fastDummies</b> (one-hot encoding for payment type, product category, customer state)
- <b>forcats / scales</b> (factor lumping, plot formatting)
- <b>randomForest</b>
- <b>xgboost</b>
- <b>pROC</b> (AUC calculation)
- <b>broom</b> (extracting logistic regression coefficients)
- <b>ggplot2</b> (visualization)

<h2>Business Problem</h2>

Customer satisfaction drives repeat purchases and referrals in online retail. For a marketplace like Olist, which connects small Brazilian sellers to customers, understanding what drives a positive or negative post-purchase review makes it possible to intervene before satisfaction drops, for example, by tightening delivery estimates or flagging product categories that consistently underperform. This project frames satisfaction as a binary classification problem: given information about an order's delivery, payment, and product characteristics, predict whether the customer will leave a positive (4-5 star) or negative (1-3 star) review.

<h2>Data</h2>

<b>Source:</b> <a href="https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce">Brazilian E-Commerce Public Dataset by Olist</a> (Kaggle), covering 100,000+ orders placed between 2016 and 2018

<b>Preparation:</b>
- Merged six raw tables (customers, orders, order items, payments, reviews, and products) into one modeling dataset
- Removed identifiers and free-text fields not useful for prediction
- Aggregated payments per order into total payment amount, number of payments, and payment type
- Kept only the most recent review per order
- Engineered <code>approval_hours</code> (time between purchase and payment approval) and <code>delayed</code> (whether the order arrived after its estimated delivery date)
- Lumped rare product categories into an "others" bucket to reduce feature sparsity
- Defined the target variable <code>positive_review</code> as 1 for 4-5 star reviews and 0 for 1-3 star reviews
- Set aside 20% of the full dataset as a holdout set before any modeling, then split the remaining 80% into training (80%) and test (20%) sets for model development

<h2>Results</h2>

Performance on the holdout set:
| Model | Accuracy | Precision | Recall | AUC |
| --- | --- | --- | --- | --- |
| Logistic Regression | 0.795 | 0.810 | 0.959 | 0.676 |
| Random Forest | 0.831 | 0.842 | 0.962 | 0.755 |
| XGBoost | 0.814 | 0.826 | 0.962 | 0.720 |

Random Forest was the strongest model on every metric, with 83% accuracy and the highest AUC (0.755). All three models achieved high recall (~96%), meaning they rarely missed a genuinely positive review, but differed more in precision and AUC (how well they separated the two classes overall).

<p align="center"> 
Most customers left positive reviews, indicating overall high satisfaction: <br/> 
<img src="images/figure1_review_distribution.png" height="80%" width="80%" alt="Distribution of Customer Satisfaction"/> 
<br /> 
<br /> 
Delayed orders were consistently associated with lower review scores: <br/> 
<img src="images/figure2_delivery_delay.png" height="80%" width="80%" alt="Customer Satisfaction vs Delivery Delay"/> 
<br /> 
<br /> 
Logistic Regression ranks delivery delay first by coefficient magnitude, with customer state also playing a role: <br/> 
<img src="images/figure3_logit_importance.png" height="80%" width="80%" alt="Logit Model - Top 10 Most Important Variables"/> 
<br /> 
<br /> 
Random Forest highlights a broader set of drivers, including total payment, price, and product weight: <br/> 
<img src="images/figure4_rf_importance.png" height="80%" width="80%" alt="Random Forest - Top 10 Most Important Variables"/> 
<br /> 
<br /> 
XGBoost also places delivery delay at the top, while emphasizing payment amount, price, and approval time: <br/> 
<img src="images/figure5_xgb_importance.png" height="80%" width="80%" alt="XGBoost - Top 10 Most Important Variables"/> 
</p>

Across all three models, <b>delivery delay</b> was consistently the single most important predictor of a positive or negative review, though the tree-based models (Random Forest and XGBoost) surfaced additional signal from payment totals, product price, and product weight that the linear logistic model captured less clearly.

<!--
 ```diff
- text in red
+ text in green
! text in orange
# text in gray
@@ text in purple (and bold)@@
```
--!>
