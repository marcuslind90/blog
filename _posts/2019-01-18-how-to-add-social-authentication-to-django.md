---
layout: post
title: How to Add Social Authentication to Django
date: 2019-01-18 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-add-social-authentication-to-django/
---

No matter what type of website your building these days, if you require some kind of authentication there is probably some kind of service or social network out there that would be a good fit for you and your application and that you could leverage for authentication and registration.

Are you building a gaming website? Why not authenticate with Blizzard's Battle.net. Are you building an application with a technology target group? Maybe you can allow authentication with their GitHub account? If you're targeting main stream audiences, then why not just let them authenticate with their Facebook, Twitter or Google accounts?

Each one of these providers have their own API's and documentation that explains how you can integrate with their service and access their user's data for authentication. It could feel a bit frustrating to have to switch it up between each project, but luckily there are some amazing open source contributers out there that can help us out.

## Use Django-Allauth for Social Login
Django have a rich community of open source contributers that create high quality packages that we can leverage. In this particular case there is [django-allauth](https://github.com/pennersr/django-allauth) which as you might guess due to its name, allows you to integrate authentication with "all" providers.

At the time of writing this article, the package allows you to authenticate with **86 unique providers** and it includes providers such as:

- Amazon
- Battle.net
- Dropbox
- Facebook
- GitHub
- Google
- Instagram
- LinkedIn
- Microsoft
- PayPal
- Spotify
- Twitter

All of them are extremely easy to implement and they all follow the same pattern, so there is no need to have to figure out some kind of unique manner of authenticating with the service. The [django-allauth](https://github.com/pennersr/django-allauth) package is something that you must look into as a Django developer, I promise that it will come in handy!

## Example of using Facebook Login
Let's go through a popular example together of how you can add Facebook Authentication to your application in a few easy steps.

### Installing django-allauth
Start off by installing the `django-allauth` package.

```bash
# Note that at the time of you reading this, there might be a 
# more recent version of the package.
pip install django-allauth>=0.37.0
```

You should then follow the [installation documentation](https://django-allauth.readthedocs.io/en/latest/installation.html) of the package and add it to your application by adding the following information to your `settings.py` file.

```python
AUTHENTICATION_BACKENDS = (
    'django.contrib.auth.backends.ModelBackend',
    'allauth.account.auth_backends.AuthenticationBackend',
)

INSTALLED_APPS = (
    ...
    # Required
    'django.contrib.auth',
    'django.contrib.messages',
    'django.contrib.sites',
    # Required
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    # Add the providers that you want to install and support
    'allauth.socialaccount.providers.facebook',
    ...
)

SITE_ID = 1
```

Let's summarize these additions and what they do:

- `AUTHENTICATION_BACKENDS` are the classes that will be used to check the values of the login form whenever its submitted. Each time you submit the form it will pass through each of the backend, and login the user with the first backend that matches the submitted form data. If no backend succeeds with logging in the user, then the authentication fails. We want to use the default `ModelBackend` to support the traditional Django users, but also add `AuthenticationBackend` to support our new Django Allauth package.
- `INSTALLED_APPS` is the list of Django applications that we want to enable. The django core applications that are listed are required for our package to work. We choose to only install the Facebook provider, but you can add as many of the package's provider as you wish.
- `SITE_ID` is the primary key of your website as part of the `django.contrib.sites` framework. This core package allows you to potentially support multiple different websites in a single Django installation. In our case its not very relevant, but it is required for our `django-allauth` package.

The next step is to add the `django-allauth` url's to your application with the following code added to `urls.py`:

```python
urlpatterns = [
    path('accounts/', include('allauth.urls')),
]
```

All it does is that it maps the package URL's to its custom forms and pages.

The final step is to run `python manage.py migrate` to add the required models and tables to your project's database. Voila you have now completed the installation!

Before you continue, make sure that you add a `Site` for your domain matching the `SITE_ID` value that you added to your settings by logging into your Django Admin and navigating to the "Sites" section.

### Adding Facebook API Credentials
After you've installed the package, it is now time to add the Facebook credentials that allow you to connect to their API and authenticate users. This is easily done using the Django Admin interface to add any required information to the new Models that was created during migration.

Go to the "Social applications" section and add a new application entry. Here you need to fill in the required information which is:

- Provider (Facebook)
- Name (Facebook)
- Client ID
- Secret Key
- Sites (Add the site that you just created in the previous step)

The Client ID and the Secret Key are the credentials that you get from Facebook. To get these credentials you have to go to [Facebook for Developers](https://developers.facebook.com/) and create a new App. 

Follow the steps and enable Facebook Login when it asks you what type of features you want access to. You should then navigate to your new Facebook application's "Settings" page to find your "App ID" (Client ID) and your "App Secret" (Secret Key).

On top of this you should also add your "App Domains" within the Facebook Settings which defines which domains that your application will access Facebook's API from. You need to define the correct domains here or else you will encounter errors. For development you can add `localhost` but you should also add your real domain name.

At this point you should be able to navigate to your website's `/accounts/signup/` URL and test the authentication. You should now be able to login with Facebook. 

### Additional things you need to add for Production
Hopefully you have now successfully tested to login to your application using Facebook authentication on your local environment, and now its ready to take this to production. To use the Facebook Authentication in a production environment you need to take a few additional steps. 

- Create a Privacy page on your website.
- Create a Terms of Service page on your website.
- Fill out remaining information on the Facebook App's Settings Page.
- Fill out the Facebook Login Settings on the Facebook Developers Dashboard

The first two steps can be completed by simply creating a simple `TemplateView` on your Django application that lists your Privacy terms and your Terms of Service. Facebook requires this and they will display these links to the user when they are authenticating. 

The third step requires you to go back to [Facebook for Developers](https://developers.facebook.com/) and complete the information required on the Settings Page of your application. This includes things such as giving the links to the newly created Terms/Privacy pages.

The fourth and final step require you to add additional information that is specifically related to the Facebook Login feature. You go to the [Facebook for Developers](https://developers.facebook.com/)  dashboard and in the left hand menu, you will see "Facebook Login" being listed under the "Products" section. 

You need to go there to ensure that you enable OAuth Login, but also that you specify the correct "Valid OAuth Redirect URIs". These will be the URL's that Facebook will attempt to redirect the user to after they've successfully authenticated.

In my case I've added my root domain and `https://<mydomain>/accounts/facebook/login/callback/`. This callback URL is the default path that the `django-allauth` package will attempt to redirect the users to after they've successfully authenticated. If you don't add these settings you will experience error messages whenever you try to login in production.

The final step is to set your applications "Status" from "Under Development" to "Live". You can do this at the top of your screen from the Facebook for Developers dashboard.

At this point you should be able to deploy your code and authenticate from your website in production! Congratulations you've just added Social Authentication to your application.

## Override Templates and Forms
The default templates for the signup page or the login page might not be the prettiest. They don't follow any particular type of styling and they are not very opinionated, instead they simply just list the authentication providers in a simple list with standard links.

As soon as you have got authentication working you will probably want to override some of these templates and implement your own interface. To do this, I have the following recommendations. 

- Copy the `django-allauth` templates folder `account/` to your own root `templates/` folder.
- Copy the `django-allauth` templates folder `socialaccount/snippets/provider_list.html` to your own root `templates/` folder.

The accounts folder contains all of the pages templates that are part of the `django-allauth` package. This includes templates for pages like Signup, Login, Logout, Password Change and more. You will have a great overview of which templates exist and you only need to modify the ones you want to, you can keep the others in original format.

I recommend you to keep things as similar as possible as the original, but mostly add things like CSS classes or wrap things in additional container divs for positioning. The templates already come with functionality such as linking to the "Forgot Password?" or giving the users the standard Django signup form to allow them to signup in a traditional manner instead of using Social providers.

### Add Crispy Forms
If you want to style the form inputs, I recommend you to install `django-crispy-forms` add simply add a filter to the form with `{{form|crispy}}` instead of manually looping through the form instance and trying to format each field the way you want to.

It's a much cleaner way of styling your forms, and it also makes sure that if you do any changes to the form it will be reflected in your templates automatically.

You can install Crispy Forms by doing the following:
	
```bash
pip install django-crispy-forms>=1.7.2
```

You then add the following to your `settings.py` file:

```python
INSTALLED_APPS = (
    ...
    'crispy_forms',
)
# This enables bootstrap4 styling, there are plenty of 
# other options that you can find within the documentation.
CRISPY_TEMPLATE_PACK = 'bootstrap4'
```

Finally you use it by adding `{% raw %}{% load crispy_forms_tags %}{% endraw %}` to your template file and then adding the `crispy` filter to the form itself by writing `{{form|crispy}}`. This will now format the form with the `CRISPY_TEMPLATE_PACK` setting that you defined within your `settings.py` file.

You can find other available template pack's within the [Crispy Forms Documentation](https://django-crispy-forms.readthedocs.io/en/latest/install.html#template-packs).
