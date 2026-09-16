# Final Project 
# STAT310

setwd("~/Desktop/SFU/FALL 2025/STAT310/Final Project")

# Load libraries and raw data
#####
library(tidyverse)
library(fastDummies)
library(scales)
library(forcats)
library(randomForest)
library(xgboost)
library(pROC)

customers <- read_csv("olist_customers_dataset.csv") 
items <- read_csv("olist_order_items_dataset.csv") 
payments <- read_csv("olist_order_payments_dataset.csv")
review <- read_csv("olist_order_reviews_dataset.csv")
orders <- read_csv("olist_orders_dataset.csv") 
products <- read_csv("olist_products_dataset.csv") 
#####

# Clean raw data
#####
## customer
customers_clean <- customers %>%
  select(-c('customer_unique_id','customer_zip_code_prefix'))

## items
items_clean <- items %>%
  select(-c('order_item_id', 'seller_id', 'shipping_limit_date'))

## payments
payments_clean <- payments %>%
  group_by(order_id) %>%
  summarise(payment_total=sum(payment_value, na.rm=TRUE),
            n_payments=n(),
            n_payment_types = n_distinct(payment_type),
            payment_type=paste(sort(unique(payment_type)), collapse=',')) %>%
  dummy_cols(select_columns = 'payment_type', split = ',',
             remove_selected_columns = TRUE, remove_first_dummy = FALSE)

## reviews
reviews_clean <- review %>%
  arrange(order_id, review_answer_timestamp) %>%
  group_by(order_id) %>%
  slice_tail(n = 1) %>% 
  ungroup() %>%
  select(c('review_score', 'order_id'))

## orders
orders_clean <- orders %>%
  mutate(approval_hours=as.numeric(difftime(order_approved_at,
                                            order_purchase_timestamp, 
                                            units='hours'))) %>%
  mutate(delayed=order_delivered_customer_date>order_estimated_delivery_date) %>%
  mutate(delayed=ifelse(delayed==TRUE,'Delayed', 'On Time')) %>%
  mutate(delivery_time=as.numeric(difftime(order_delivered_customer_date,
                                           order_purchase_timestamp,
                                           units='hours'))) %>%
  mutate(estimated_delivery_time=as.numeric(difftime(order_estimated_delivery_date,
                                                     order_purchase_timestamp,
                                                     units='hours'))) %>%
  select(-c('order_status', 'order_delivered_carrier_date', 'order_purchase_timestamp',
            'order_approved_at','order_delivered_customer_date', 'order_estimated_delivery_date'))

## products
products_clean <- products %>%
  select(-c('product_name_lenght', 'product_description_lenght'))

#####

# Merge clean data
#####
eda_data <- orders_clean %>%
  left_join(customers_clean, by='customer_id') %>%
  left_join(items_clean, by='order_id') %>%
  left_join(products_clean, by='product_id') %>%
  left_join(payments_clean, by='order_id') %>%
  left_join(reviews_clean, by='order_id') %>%
  select(-c('order_id', 'customer_id', 'product_id', 'customer_city',)) %>%
  mutate(product_category_name=fct_lump(product_category_name, n=10, other_level='others')) %>%
  mutate(customer_state=as.factor(customer_state)) %>%
  na.omit()

olist_data_full <- eda_data %>%
  mutate(positive_review=ifelse(review_score>=4,1,0)) %>%
  mutate(delayed=ifelse(delayed=='Delayed',1,0)) %>%
  select(-c(review_score, delivery_time, estimated_delivery_time,
            n_payment_types, payment_type_not_defined))

#####

# Explanatory Data Analysis
#####
## Distribution of review score
ggplot(eda_data, aes(x=review_score)) +
  geom_bar(fill='#9BBB59') + 
  labs(title='Distribution of Customer Satisfaction',
       x='Review Score', 
       y='Count', 
       caption='Figure 1') +
  scale_y_continuous(labels=label_number(scale=1/1000,suffix='K')) +
  theme_classic()

## Review score vs Delivery delay
ggplot(eda_data, aes(x=delayed,y=review_score, fill=delayed)) +
  geom_boxplot(alpha=0.7) +
  scale_fill_manual(values=c('On Time'='#C7EFCF', 'Delayed'='#5AA469')) +
  labs(title='Customer Satisfaction vs Delivery Delay', 
       x='Delivery Status', 
       y='Review Score',
       caption='Figure 2') +
  theme_classic() +
  theme(legend.position='none')
#####

# Holdout sample 
#####
set.seed(712)
test_index <- sample(seq_len(nrow(olist_data_full)),
                     size = floor(0.20 * nrow(olist_data_full)),
                     replace = FALSE)

holdout_data  <- olist_data_full[test_index, ]
olist_data <- olist_data_full[-test_index, ]
#####

# Logistic Regression
#####
set.seed(712)
logit_index <- sample(1:nrow(olist_data), 0.8*nrow(olist_data))
logit_train <- olist_data[logit_index, ]
logit_test <- olist_data[-logit_index, ]

logit_model <- glm(positive_review ~ ., 
                   data=logit_train, 
                   family=binomial(link="logit"))

logit_prob <- predict(logit_model, newdata=logit_test, type="response")
logit_pred <- ifelse(logit_prob >= 0.5, 1, 0)

logit_accuracy <- mean(logit_pred == logit_test$positive_review)

TP_logit <- sum(logit_pred == 1 & logit_test$positive_review == 1)
FP_logit <- sum(logit_pred == 1 & logit_test$positive_review == 0)
FN_logit <- sum(logit_pred == 0 & logit_test$positive_review == 1)

logit_precision <- TP_logit / (TP_logit + FP_logit)
logit_recall <- TP_logit / (TP_logit + FN_logit)
logit_auc <- auc(logit_test$positive_review, logit_prob) 
#####

# Random Forest
#####

rf_data <- olist_data %>%
  mutate(positive_review=as.factor(positive_review))

set.seed(712)
rf_index <- sample(1:nrow(rf_data), 0.8*nrow(rf_data))
rf_train <- rf_data[rf_index, ]
rf_test <- rf_data[-rf_index, ]

test_y_factor <- rf_test$positive_review
test_y <- as.numeric(test_y_factor) - 1   

set.seed(712)
rf_model <- randomForest(positive_review ~ ., 
                         data=rf_train, 
                         ntree=300,
                         mtry=floor(sqrt(ncol(rf_train) - 1)),
                         importance = TRUE)

rf_prob <- predict(rf_model, newdata=rf_test, type='prob')[,2]
rf_pred <- ifelse(rf_prob > 0.5, 1, 0)

rf_accuracy <- mean(rf_pred == test_y)

TP_rf <- sum(rf_pred == 1 & test_y == 1)
FP_rf <- sum(rf_pred == 1 & test_y == 0)
FN_rf <- sum(rf_pred == 0 & test_y == 1)

rf_precision <- TP_rf / (TP_rf + FP_rf)
rf_recall    <- TP_rf / (TP_rf + FN_rf)
rf_auc <- auc(test_y, rf_prob) 
#####

# XGBoost
#####
boost_data <- olist_data %>%
  dummy_cols(select_columns=c('product_category_name','customer_state'),
             remove_selected_columns=TRUE, 
             remove_first_dummy=TRUE)

set.seed(712)
boost_index <- sample(1:nrow(boost_data), 0.8*nrow(boost_data))
boost_train <- boost_data[boost_index, ]
boost_test <- boost_data[-boost_index, ]

train_label <- boost_train$positive_review
test_label <- boost_test$positive_review

boost_train <- subset(boost_train, select = -positive_review)
boost_test <- subset(boost_test, select = -positive_review)

boost_train_matrix <- as.matrix(boost_train)
boost_test_matrix <- as.matrix(boost_test)

train_label <- as.numeric(train_label)
test_label <- as.numeric(test_label)

boost_model <- xgboost(data=boost_train_matrix,
                       label=train_label,
                       max_depth = 4,          
                       lambda = 1,             
                       nrounds = 600,          
                       early_stopping_rounds = 25,
                       verbose = 1)

boost_pred_prob <- predict(boost_model, boost_test_matrix)
boost_pred <- ifelse(boost_pred_prob > 0.5, 1, 0)

boost_accuracy <- mean(boost_pred == test_label)

TP_boost <- sum(boost_pred == 1 & test_label == 1)
FP_boost <- sum(boost_pred == 1 & test_label == 0)
FN_boost <- sum(boost_pred == 0 & test_label == 1)

boost_precision <- TP_boost / (TP_boost + FP_boost)
boost_recall <- TP_boost / (TP_boost + FN_boost)

boost_auc <- auc(test_label, boost_pred_prob)
#####

# Results
#####
model_summary <- data.frame(Model = c("Logistic Regression", "Random Forest", "XGBoost"),
                            Accuracy = c(logit_accuracy, rf_accuracy, boost_accuracy),
                            Precision = c(logit_precision, rf_precision, boost_precision),
                            Recall = c(logit_recall, rf_recall, boost_recall),
                            AUC = c(logit_auc,rf_auc,boost_auc))
model_summary

#####

# Variable Importance
#####

## Logit model
logit_std <- glm(positive_review ~ ., 
                 data = logit_train,
                 family = binomial(link="logit"))

logit_importance <- broom::tidy(logit_std) %>%
  filter(term != "(Intercept)") %>%
  mutate(importance = abs(estimate)) %>%
  arrange(desc(importance))

logit_top10 <- logit_importance %>%
  top_n(10, importance) %>%
  mutate(Model = "Logit") %>%
  select(Model, Variable = term, Importance = importance)

logit_plot <- logit_top10 %>%
  mutate(Variable = reorder(Variable, Importance)) %>%
  ggplot(aes(x = Importance, y = Variable)) +
  geom_col(fill = '#AEDFA0') +
  labs(title = 'Logit Model – Top 10 Most Important Variables',
       x = 'Importance (Coefficient)',
       y = 'Variable',
       caption = 'Figure 3') +
  theme_classic()

logit_plot

## Random Forest
rf_importance <- importance(rf_model, type = 1) 
rf_importance <- data.frame(
  Variable = rownames(rf_importance),
  Importance = rf_importance[,1]
) %>%
  arrange(desc(Importance))

rf_top10 <- rf_importance %>%
  top_n(10, Importance) %>%
  mutate(Model = "Random Forest") %>%
  select(Model, Variable, Importance)

rf_plot <- rf_top10 %>%
  mutate(Variable = reorder(Variable, Importance)) %>%
  ggplot(aes(x = Importance, y = Variable)) +
  geom_col(fill = '#9BBB59') +
  labs(title = 'Random Forest – Top 10 Most Important Variables',
       x = 'Importance (Mean Decrease Gini)',
       y = 'Variable',
       caption = 'Figure 4') +
  theme_classic()

rf_plot

## XGBoost
xgb_imp <- xgb.importance(model = boost_model)

xgb_importance <- xgb_imp %>%
  select(Feature, Gain, Cover, Frequency) %>%
  arrange(desc(Gain))

xgb_top10 <- xgb_importance %>%
  top_n(10, Gain) %>%
  mutate(Model = "XGBoost", Importance = Gain) %>%
  select(Model, Variable = Feature, Importance)

xgb_plot <- xgb_top10 %>%
  mutate(Variable = reorder(Variable, Importance)) %>%
  ggplot(aes(x = Importance, y = Variable)) +
  geom_col(fill = '#5AA469') +
  labs(title = 'XGBoost – Top 10 Most Important Variables',
       x = 'Importance (Gain)',
       y = 'Variable',
       caption = 'Figure 5') +
  theme_classic()

xgb_plot

#####

# Houldout set evaluation
#####

x_holdout <- as.matrix(select(holdout_data, -positive_review))
y_holdout <- holdout_data$positive_review

## Logistic
logit_hold_prob <- predict(logit_model, newdata=holdout_data, type="response")
logit_hold_pred <- ifelse(logit_hold_prob >= 0.5, 1, 0)

logit_hold_accuracy <- mean(logit_hold_pred == y_holdout)
logit_hold_precision <- sum(logit_hold_pred == 1 & y_holdout == 1) / sum(logit_hold_pred == 1)
logit_hold_recall <- sum(logit_hold_pred == 1 & y_holdout == 1) / sum(y_holdout == 1)
logit_hold_auc <- auc(y_holdout, logit_hold_prob)


## Random Forest
rf_hold_prob <- predict(rf_model, newdata=holdout_data, type='prob')[,2]
rf_hold_pred <- ifelse(rf_hold_prob >= 0.5, 1, 0)

rf_hold_accuracy <- mean(rf_hold_pred == y_holdout)
rf_hold_precision <- sum(rf_hold_pred == 1 & y_holdout == 1) / sum(rf_hold_pred == 1)
rf_hold_recall <- sum(rf_hold_pred == 1 & y_holdout == 1) / sum(y_holdout == 1)
rf_hold_auc <- auc(y_holdout, rf_hold_prob) 


## XGBoost
hold_boost <- holdout_data %>%
  dummy_cols(select_columns=c('product_category_name','customer_state'),
             remove_selected_columns=TRUE, 
             remove_first_dummy=TRUE)

x_hold_boost <- as.matrix(select(hold_boost, -positive_review))
y_hold_boost <- as.numeric(hold_boost$positive_review)

boost_hold_prob <- predict(boost_model, x_hold_boost)
boost_hold_pred <- ifelse(boost_hold_prob >= 0.5, 1, 0)

boost_hold_accuracy <- mean(boost_hold_pred == y_hold_boost)
boost_hold_precision <- sum(boost_hold_pred == 1 & y_hold_boost == 1) / sum(boost_hold_pred == 1)
boost_hold_recall <- sum(boost_hold_pred == 1 & y_hold_boost == 1) / sum(y_hold_boost == 1)
boost_hold_auc <- auc(y_hold_boost, boost_hold_prob)  

## Table Summary
hold_summary <- data.frame(Model=c("Logistic Regression", "Random Forest", "XGBoost"),
                           Accuracy=c(logit_hold_accuracy, rf_hold_accuracy, boost_hold_accuracy),
                           Precision=c(logit_hold_precision, rf_hold_precision, boost_hold_precision),
                           Recall=c(logit_hold_recall, rf_hold_recall, boost_hold_recall),
                           AUC=c(logit_hold_auc, rf_hold_auc, boost_hold_auc))

hold_summary
#####
