<h1>Predicting Customer Satisfaction in E-Commerce</h1>

 ### [View the Full Report](https://youtu.be/7eJexJVCqJo)

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

<p align="center">
Launch the utility: <br/>
<img src="https://i.imgur.com/62TgaWL.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
<br />
<br />
Select the disk:  <br/>
<img src="https://i.imgur.com/tcTyMUE.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
<br />
<br />
Enter the number of passes: <br/>
<img src="https://i.imgur.com/nCIbXbg.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
<br />
<br />
Confirm your selection:  <br/>
<img src="https://i.imgur.com/cdFHBiU.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
<br />
<br />
Wait for process to complete (may take some time):  <br/>
<img src="https://i.imgur.com/JL945Ga.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
<br />
<br />
Sanitization complete:  <br/>
<img src="https://i.imgur.com/K71yaM2.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
<br />
<br />
Observe the wiped disk:  <br/>
<img src="https://i.imgur.com/AeZkvFQ.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
</p>

<!--
 ```diff
- text in red
+ text in green
! text in orange
# text in gray
@@ text in purple (and bold)@@
```
--!>
