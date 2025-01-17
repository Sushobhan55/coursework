########################################
# load libraries
########################################

# load some packages that we'll need
library(tidyverse)
library(scales)
library(lubridate)
library(gridExtra)

# be picky about white backgrounds on our plots
theme_set(theme_bw())

# load RData file output by load_trips.R
load('trips.RData')


########################################
# plot trip data
########################################

# plot the distribution of trip times across all rides (compare a histogram vs. a density plot)
histogram_1 <- trips %>% 
  ggplot(aes(x = tripduration/60)) + 
  geom_histogram(bins = 100, color = 'blue') + 
  scale_x_continuous(limits = c(0, 100)) + 
  scale_y_continuous(label = comma) + 
  labs(x = 'Trip duratation (in minutes)', 
       title = 'Trip times across all rides')
density_plot_1 <- trips %>% 
  ggplot(aes(x = tripduration/60)) + 
  geom_density(color = 'blue', fill = 'blue') + 
  scale_x_continuous(limits = c(0, 100)) + 
  labs(x = 'Trip duratation (in minutes)',
       title = 'Trip times across all rides')

grid.arrange(histogram_1, density_plot_1, ncol = 2)

# plot the distribution of trip times by rider type indicated using color and fill (compare a histogram vs. a density plot)
histogram_2 <- trips %>%
  ggplot(aes(x = tripduration/60, color = usertype, fill = usertype))+
  geom_histogram(bins = 60) +
  scale_x_continuous(limits = c(0, 100))+
  scale_y_continuous(label = comma) +
  facet_wrap(~ usertype) +
  labs(x = 'Trip duration', 
       title = 'Trip times by rider type')

density_plot__2 <- trips %>%
  ggplot(aes(x = tripduration/60, color = usertype, fill = usertype))+
  geom_density() +
  scale_x_continuous(limits = c(0, 100))+
  facet_wrap(~ usertype) +
  labs(x = 'Trip duration', 
       title = 'Trip times by rider type')

grid.arrange(histogram_2, density_plot__2, ncol = 1)

# plot the total number of trips on each day in the dataset
trips %>%
  group_by(ymd) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = ymd, y = count)) +
  scale_y_continuous(label = comma) +
  geom_point(aes(color = factor(month(ymd), levels = 1:12, labels = month.name))) +
  labs(x = 'Day', 
       y = 'No. of trips', 
       title = 'Total number of trips in each day',
       color = 'Month')

# plot the total number of trips (on the y axis) by age (on the x axis) and gender (indicated with color)
trips %>%
  count(birth_year, gender) %>%
  filter(birth_year > 1) %>%
  ggplot(aes(x = (2014 - birth_year), y = n, color = gender)) + 
  scale_y_continuous(label = comma) +
  geom_point() +
  labs(x = 'Age', 
     y = 'No. of trips', 
     title = 'Total number of trips by age and gender',
     color = 'Gender')
  

# plot the ratio of male to female trips (on the y axis) by age (on the x axis)
# hint: use the pivot_wider() function to reshape things to make it easier to compute this ratio
# (you can skip this and come back to it tomorrow if we haven't covered pivot_wider() yet)
trips %>% 
  mutate(age = 2014 - birth_year) %>%
  group_by(gender, age) %>%
  summarize(count = n()) %>%
  pivot_wider(names_from = gender, values_from = count) %>%
  ggplot(aes(x = age, y = Male/Female)) +
  geom_point() +
  geom_smooth(method = "lm") +
  xlim(c(18, 90)) +
  labs(x = 'Age',
       title = 'Male to female ratio for an age group')
  

########################################
# plot weather data
########################################
# plot the minimum temperature (on the y axis) over each day (on the x axis)
weather %>%
  ggplot(aes(x = ymd, y = tmin)) +
  geom_point() +
  labs(x = 'Days',
       y = 'Minimum temperature')

# plot the minimum temperature and maximum temperature (on the y axis, with different colors) over each day (on the x axis)
# hint: try using the pivot_longer() function for this to reshape things before plotting
# (you can skip this and come back to it tomorrow if we haven't covered reshaping data yet)
weather %>%
  group_by(tmin, tmax, ymd) %>%
  pivot_longer(c('tmin', 'tmax'), names_to = 'temperature_type', values_to = 'temperature') %>%
  ggplot(aes(x = ymd, y = temperature, color = temperature_type)) +
  geom_point()+
  labs(x = 'Day',
       title = 'minimum and maiximum temperature')

########################################
# plot trip and weather data
########################################

# join trips and weather
trips_with_weather <- inner_join(trips, weather, by="ymd")

# plot the number of trips as a function of the minimum temperature, where each point represents a day
# you'll need to summarize the trips and join to the weather data to do this
trips_with_weather %>%
  group_by(ymd, tmin) %>%
  summarize(count = n(), .groups = 'drop') %>%
  ggplot(aes(x = tmin, y = count, label = 1:28)) +
  labs(x = 'Minimum temperature',
       y = 'No. of trips') +
  geom_point() +
  geom_text(hjust=-0.3)

# repeat this, splitting results by whether there was substantial precipitation or not
# you'll need to decide what constitutes "substantial precipitation" and create a new T/F column to indicate this
trips_with_weather %>%
  mutate(substantial_prcp = prcp > 0.1) %>%
  group_by(ymd, tmin, substantial_prcp) %>%
  summarize(count = n(), .groups = 'drop') %>%
  ggplot(aes(x = tmin, y = count, label = 1:28)) +
  labs(x = 'Minimum temperature',
       y = 'No. of trips',
       title = 'Trips tend to be low when there is substantial precipitation.') +
  geom_point() +
  geom_text(hjust=-0.3) +
  facet_wrap(~substantial_prcp, ncol = 1)

# add a smoothed fit on top of the previous plot, using geom_smooth
trips_with_weather %>%
  mutate(substantial_prcp = prcp > 0.1) %>%
  group_by(ymd, tmin, substantial_prcp) %>%
  summarize(count = n(), .groups = 'drop') %>%
  ggplot(aes(x = tmin, y = count, label = 1:28)) +
  labs(x = 'Minimn))um temperature',
       y = 'No. of trips',
       title = 'Trips tend to be low when there is substantial precipitation.') +
  geom_point() +
  geom_smooth() +
  geom_text(hjust = -0.3) +
  facet_wrap(~substantial_prcp, ncol = 1)

# compute the average number of trips and standard deviation in number of trips by hour of the day
# hint: use the hour() function from the lubridate package
summary_by_hour <- trips_with_weather %>%
  mutate(hour = hour(starttime)) %>%
  group_by(hour) %>%
  count(ymd) %>%
  summarize(average = mean(n), std = sd(n))

# plot the above
ave_plot_1 <- summary_by_hour %>%
  ggplot(aes(hour, average, label = 0:23)) +
  geom_point(color = 'blue') +
  geom_text(hjust = -0.3) 
std_plot_1 <- summary_by_hour %>%
  ggplot(aes(hour, std, label = 0:23)) +
  geom_point(color = 'red') +
  geom_text(hjust = -0.3)
grid.arrange(ave_plot_1, std_plot_1, ncol = 1)

# repeat this, but now split the results by day of the week (Monday, Tuesday, ...) or weekday vs. weekend days
# hint: use the wday() function from the lubridate package
ave_plot_2 <- trips_with_weather %>%
  mutate(day = wday(starttime)) %>%
  group_by(day) %>%
  count(ymd) %>%
  summarize(average = mean(n), std = sd(n)) %>%
  ggplot(aes(day, average, label = c('mon','tue','wed','thu','fri','sat','sun'))) +
  geom_point(color = 'blue') +
  geom_text(hjust = -0.3) 
std_plot_2 <- trips_with_weather %>%
  mutate(day = wday(starttime)) %>%
  group_by(day) %>%
  count(ymd) %>%
  summarize(average = mean(n), std = sd(n)) %>%
  ggplot(aes(day, std, label = c('mon','tue','wed','thu','fri','sat','sun'))) +
  geom_point(color = 'red') +
  geom_text(hjust = -0.3)
grid.arrange(ave_plot_2, std_plot_2, ncol = 1)

