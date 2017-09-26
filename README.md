<<<<<<< HEAD
* An overview of environments
* Setting up logging on different environments
* Dealing with email

## An overview of environments

So far we've been working on our project only in the context of a development environment, but it's important to consider that we're eventually going to want to deploy to a remote test environment, and hopefully soon after, a production website. A given project can have many environments, especially large projects that are entertaining multiple, concurrent development efforts. Each environment introduces new state, and managing that state can be really cumbersome if you don't have a solid set up. Therefore, it's important to start considering your environments early on in your development process.

We've already talked a bit about the centrepiece of environment management in SilverStripe, the `.env` file. Just as a reminder, this file is intended to reside above the web root to provide environment-specific variables to the project. This allows you to deploy one coherent codebase to each environment without having to write conditional logic to serve each environment. It does introduce the complexity of needing a higher level of write access to your server, however, so you'll want to make sure you have shell access or a highly privileged FTP account that will allow you to edit files above the web root.

## Setting up logging on different environments

One of the services you'll want enabled on test and, even more so, production, is good error logging and notification. In our dev environment, we want to suppress this, as we don't mind getting verbose errors, but once the project is on the web, you'll want to suppress showstopping errors as much as possible and simply log them out so you can proactively fix them.

As of version 4.0, SilverStripe uses the [PSR-3 logging](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md) standard. This means it is easy to swap out the logger with an alternative implementation, and allows your SilverStripe application to play nicely with other frameworks and libraries.

To log errors, just access the logger interface with Injector.

```php
use SilverStripe\Core\Injector\Injector;
use Psr\Log\LoggerInterface;

Injector::inst()->get(LoggerInterface::class)->error('Description of error');
```

Also available per the PSR-3 standard are:

* `emergency()`
* `alert()`
* `critical()`
* `warning()`
* `notice()`
* `info()`
* `debug()`
* `log()`

For a full list, see the PSR-3 documentation](http://www.php-fig.org/psr/psr-3/).

It's a good idea to throw these in your user code where appropriate. Logging can be very useful for debugging. When using the logger in your classes, you need not keep going through `Injector` to get a logger instance. A cleaner approach is to inject the logger as a dependency.

```php
namespace My\App;

use Psr\Log\LoggerInterface;
use PageController;

class MyPageController extends PageController
{
  private static $dependencies = [
    'logger' => '%$' . LoggerInterface::class
  ];
  
  protected $shouldFail = true;
  
  public $logger;
  
  public function doSomething()
  {
    if ($this->shouldFail) {
      $this->logger->log('It failed');
    }
  }
}
```

What all of these logging methods acutally do depends on the implementation of `LoggerInterface` that you're using. By default, SilverStripe ships with [Monolog](https://github.com/Seldaek/monolog), a logging library that comes with its own PSR-3 logging implementation, `Monolog\Logger`.

The `Monolog\Logger` class supports *handlers*, which must implement their own `HandlerInterface` definition. You can add as many handlers as you like. Some commonly used handlers ship with SilverStripe Framework.

Here's an example of adding an email handler. Any error that happens at or above the given logging level will send an email to an administrator. Let's make anything `error()` and above send an email.

*mysite/_config/logging.yml*
```yml
SilverStripe\Core\Injector\Injector:
  Psr\Log\LoggerInterface: 
    calls:
      EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
  EmailHandler:
      class: Monolog\Handler\NativeMailerHandler
      constructor:
        - errors@example.com
        - Error reported on example.com
        - admin@example.com
        - error
      properties:
        ContentType: text/html
        Formatter: %$SilverStripe\Logging\DetailedErrorFormatter
```

Since email is a pretty aggressive form of error notification, we probably don't want to sent it from anywhere other than the live environment. Let's put this in a conditional block.

*mysite/_config/logging.yml*
```yml
    --- 
    Name: lessons-live-logging
    Only:
      environment: live
    ---
    SilverStripe\Core\Injector\Injector:
     Psr\Log\LoggerInterface: 
      calls:
        EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
    #...
```


A better option for low-level errors is writing to a log file. Let's set that up for anything over `notice()` level.

*mysite/_config/logging.yml*
```yml
    ---
    Name: lessons-all-logging
    ---
    SilverStripe\Core\Injector\Injector:
      Psr\Log\LoggerInterface: 
        calls:
          FileLogger: [ pushHandler, [ %$FileLogger ] ]
      FileLogger:
        class: Monolog\Handler\StreamHandler
        constructor:
          - "../errors.log"
          - "notice"
```

Let's make sure that error log doesn't get checked into our repository by adding it to `.gitignore`.

<<<<<<< HEAD
*.gitignore*
```
...
# ignore error log
errors.log
```

## Dealing with email
=======
So now that we have a good understanding of `ViewableData`, let's play around with some of its features. Right now, we're just returning a string to the template for our Ajax response. Let's instead return a partial template.

At the centre of dealing with Ajax responses is the use of includes in your Layout template. Let's take everything in the `.main` div, and export it to an include called `PropertySearchResults`.

*themes/one-ring/templates/SilverStripe/Lessons/Includes/PropertySearchResults.ss*
```html
<!-- BEGIN MAIN CONTENT -->
<div class="main col-sm-8">
	<% include SilverStripe/Lessons/PropertySearchResults %>				
</div>	
<!-- END MAIN CONTENT -->
=======
## What we'll cover
* What are we working towards?
* Updating the template: Working backwards
* Updating the controller to use generic data

## What are we working towards?

Up until now, the data on our templates has been pretty one-sided. It's sourced from the database, and we render the fields from one or many returned records on the template. Often times, however, the template and the database are not so tightly coupled. There's actually no rule saying that all template data has to come from the database

Ultimately what we're teaching in this lesson is the concept of *composable UI elements*. As you may know, composable components are a rapidly accelerating trend in application development as developers and designers seek to maintain a high level of agility and reusability.

Being composable, these components are essentially "dumb" and only really know how to do one thing, which is render some UI based on the configuration that has been passed to them, which is what we'll call a *composition*.

In the context of our project, we'll be lighting up the search filter toggle buttons in the sidebar of our property search page. The purpose of these buttons is to show the user what search filters have been applied, and to offer an option to remove them and refresh the search page.

## Updating the template: Working backwards

A lot of developers, including myself, find it easier to work backwards with problems like this, which means starting from the template and adding the backend afterward. Let's look at these filter buttons and try to abtract them into something we can use.

As we can see, they're all statically contained in a `ul` tag at the moment.

```html
<ul class="chzn-choices">
   <li class="search-choice"><span>New York</span><a href="#" class="search-choice-close"></a></li>
   <li class="search-choice"><span>Residential</span><a href="#" class="search-choice-close"></a></li>
   <li class="search-choice"><span>3 bedrooms</span><a href="#" class="search-choice-close"></a></li>
   <li class="search-choice"><span>2 bathrooms</span><a href="#" class="search-choice-close"></a></li>
   <li class="search-choice"><span>Min. $150</span><a href="#" class="search-choice-close"></a></li>
   <li class="search-choice"><span>Min. $400</span><a href="#" class="search-choice-close"></a></li>
</ul>
```

### The wrong way to do it

One approach that may come to mind is using a long series of display logic to output all of the possible options, like so:

```html
<ul class="chzn-choices">
<% if $LocationFilter %>
   <li class="search-choice"><span>$LocationFilter</span><a href="#" class="search-choice-close"></a></li>
<% end_if %>

<% if $BedroomFilter %>
   <li class="search-choice"><span>$BedroomFilter bedrooms</span><a href="#" class="search-choice-close"></a></li>
<% end_if %>

<!-- etc... -->
</ul>
```

This might look reasonable at first, it's going to lead to nothing but problems. There are a number of things wrong with this approach.

* It pollutes your template with syntax, and a lot of repeated markup
* It pollutes your controller with a lot of repetative property assignments and/or methods
* It creates more parity between your controller and your template. If you ever want to add or remove a new search option, you have to remember to update the template.
* We have to repurpose the *value* of the filter as its *label*, e.g. `$BedroomFilter bedrooms`, and at some point that's just not going to work. Search filters are often not human-readable, such as IDs.

### A better approach

If the sight of `li` tags nested in a `ul` is becoming almost synonymous with the `<% loop %>` control to you, that's a good sign. We're definitely going to need a loop here. This will keep the UI much cleaner, and it will give us more control over the output, as we'll have a chance to *compose* each member of the loop. Let's add that now, and make up the rest as we go.

```html
<ul class="chzn-choices">
   <% loop $ActiveFilters %>
     	<li class="search-choice"><span>New York</span><a href="#" class="search-choice-close"></a></li>
   <% end_loop %>
</ul>
```

Make sense so far? Again, we're working backwards, so the `$ActiveFilters` piece is merely semantic right now. 

Let's now just go through brainstorm some property names for all the dynamic content.

```html
<ul class="chzn-choices">
   <% loop $ActiveFilters %>
   		<li class="search-choice"><span>$Label</span><a href="$RemoveLink" class="search-choice-close"></a></li>
   <% end_loop %>
</ul>
```

We've added the properties `$Label` and `$RemoveLink`, which we can assume are the only two distinguishing traits of each filter button.

## Updating the controller

Now that our template syntax is in place, we need to configure the controller to feed this data to the template. We could write a new method called `ActiveFilters()` (or `getActiveFilters()`) that inspects the request and returns something, but given that there's only one endpoint for our search page, I think it makes more sense at this point in the project to create the filter UI elements as they're being applied to the list.

### Creating an arbitrary list

In order to invoke the `<% loop %>` block, we of course will need some kind of iteratable list. So far, we've been using `SilverStripe\ORM\DataList`, which represents a list of records associated with a database query. Since our filter UI elements are not coming from the database, we'll need something more primitive. In this case, `SilverStripe\ORM\ArrayList` is an ideal choice.

At the top of our `index()` action, let's instantiate that list.

*mysite/code/PropertySearchPageController.php*
```php
//...
use SilverStripe\ORM\ArrayList;

class PropertySearchPageController extends PageController
{
	public function index(HTTPRequest $request)
	{
		$properties = Property::get();
		$filters = ArrayList::create();
	
		//...
	}
	//...
>>>>>>> Begin lesson 18
```
Now, we just need to fill our list with data.

### Remember ViewableData?
To populate the list, we'll revisit our old friend `SilverStripe\View\ViewableData` from the previous tutorial. Just as a recap, `ViewableData` is a primitive object that is ready to be rendered on a template. One type of `ViewableData` is `DataObject`, which we've been using all along to render content from the database.

You will rarely need to use the `ViewableData` class itself, but its immediate descendant, `SilverStripe\View\ArrayData` is very flexible and couldn't be simpler to implement. It's basically just a glorified array. All you have to do is instantiate it with an array of key/value pairs that will translate to `$Variable` template variables, and render their associated values.

Let's add the filter for the `Keywords` filter.

*mysite/code/PropertySearchPageController.php*
```php
//...
use SilverStripe\View\ArrayData;
use SilverStripe\Control\HTTP;

class PropertySearchPageController extends PageController
{

	public function index(HTTPRequest $request)
	{
		
		//...
		
		if ($search = $request->getVar('Keywords')) {
			$filters->push(ArrayData::create([
				'Label' => "Keywords: '$search'",
				'RemoveLink' => HTTP::setGetVar('Keywords', null)
			]));

			$properties = $properties->filter([
				'Title:PartialMatch' => $search
			]);
		}
		
		//..

```

Using the `push()` method on `ArrayList`, we add `ArrayData` objects to it. Each one has `Label` and `RemoveLink` properties, as required by the template. The `RemoveLink` property implements an obscure utility method from the `SilverStripe\Control\HTTP` helper class. All it does is take the current URI and set a given query parameter to a given value. In this case, we're setting it to `null` to effectively remove the filter.

<<<<<<< HEAD
* Assign `$paginatedProperties` to a public property on the controller
* Explicitly pass it to the template using `customise()`.
>>>>>>> Lesson 17 complete

While we're on the topic of email, let's take some control over transactional emails in our environments. This can be a really annoying problem for a couple of reasons. For one, if we're testing with real data, we don't want transactional emails to be sent to real users from our development environment. Second, we want to be able to test whether those emails would be sent, and what their contents would be if we were in production.

A simple solution to this problem is to simply force the "to" address to go to you in the dev environment. You can configure this in the config yaml.

<<<<<<< HEAD
*mysite/_config/config.yml*
```yaml
Email:
  send_all_emails_to: 'me@example.com'
=======
=======
The next filter is for the availability date range. It actually doesn't offer a whole lot of utility to the user to display this as a toggleable filter, especially since it's actually a composite filter of `ArrivalDate` and `Nights`, so let's skip this one.

The next several are pretty straightforward. Let's add the filter UI elements for Bedrooms, Bathrooms, and Min/Max Price.

*mysite/code/PropertySearchPageController.php*
```php
>>>>>>> Begin lesson 18
	public function index(HTTPRequest $request)
	{
		
		//...

		if ($bedrooms = $request->getVar('Bedrooms')) {
			$filters->push(ArrayData::create([
				'Label' => "$bedrooms bedrooms",
				'RemoveLink' => HTTP::setGetVar('Bedrooms', null)
			]));

			$properties = $properties->filter([
				'Bedrooms:GreaterThanOrEqual' => $bedrooms
			]);
		}

<<<<<<< HEAD
		return [
			'Results' => $paginatedProperties
		];
	}
}
>>>>>>> Lesson 17 complete
```

<<<<<<< HEAD
Pretty straightforward, but we're forgetting something. We don't want this setting to apply to all environments. We need to ensure that this yaml is only loaded in the dev environment. We're not writing PHP, so we don't have the convenience of if/else blocks, but fortunately, the SilverStripe YAML parser affords us a basic API for conditional logic.

*mysite/_config/email.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
```

Perhaps in the test and production environments, we want to monitor transactional email from a bit of a distance. We could force a BCC to our email address in that case.

*mysite/_config/email.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
    ---
    Name: live-email
    Except:
      environment: dev
    ---
    Email:
      bcc_all_emails_to: 'me@example.com'
=======
=======
		if ($bathrooms = $request->getVar('Bathrooms')) {
			$filters->push(ArrayData::create([
				'Label' => "$bathrooms bathrooms",
				'RemoveLink' => HTTP::setGetVar('Bathrooms', null)
			]));

			$properties = $properties->filter([
				'Bathrooms:GreaterThanOrEqual' => $bathrooms
			]);
		}

		if ($minPrice = $request->getVar('MinPrice')) {
			$filters->push(ArrayData::create([
				'Label' => "Min. \$$minPrice",
				'RemoveLink' => HTTP::setGetVar('MinPrice', null)
			]));
>>>>>>> Begin lesson 18

			$properties = $properties->filter([
				'PricePerNight:GreaterThanOrEqual' => $minPrice
			]);
		}

		if ($maxPrice = $request->getVar('MaxPrice')) {
			$filters->push(ArrayData::create([
				'Label' => "Max. \$$maxPrice",
				'RemoveLink' => HTTP::setGetVar('MaxPrice', null)
			]));

			$properties = $properties->filter([
				'PricePerNight:LessThanOrEqual' => $maxPrice
			]);
		}

		//...
	}

```

### Passing the filters to the template

<<<<<<< HEAD
>>>>>>> Lesson 17 complete
```

This works okay, but it's kind of broad. If we have other developers on the project, they're not going to get any emails, and we also can't accurately test from our dev environment what the "to" address would actually be in production or test.

### MailCatcher

A much more thorough solution is to use a thirdparty tool to capture outgoing emails from your dev environment. There are a few of these tools available, but the one I like, and recommend, is [MailCatcher](https://mailcatcher.me/). Follow the instructions on the home page to install the software, and with just a bit of configuration, you can pipe all email into a local inbox. To browse the inbox, simply visit localhost:1080. Now, you can monitor all outgoing emails, and know exactly who would receive them and what their contents would be in a production environment.
=======
Just like our custom variable `Results`, we'll pass the `ActiveFilters` list to the template through an array.

*mysite/code/PropertySearchPageController.php*
```php
	public function index(HTTPRequest $request) {
		
		//...

		$paginatedProperties = PaginatedList::create(
			$properties,
			$request
		)->setPageLength(15)
		 ->setPaginationGetVar('s');

		$data = array (
			'Results' => $paginatedProperties,
			'ActiveFilters' => $filters			
		);

		//...
	}
```

Reload the page, and you should have working filter buttons now!
>>>>>>> Begin lesson 18
