We'll begin by adding and improving tests for our module. We'll learn about a few SilverStripe tools, and use them to increase test coverage for the important parts of our code.

Then we'll connect our module to continuous integration services. These will monitor our code and let us know when tests break or code quality declines.

We'll document our module, and learn about some of the ways SilverStripe uses this documentation to power silverstripe.org.

Then we'll learn about the new code style guidelines and use tools to format our code automatically for us.

We'll add a few community files. These will help new users get to grips with our module and new contributors to know exactly how they can contribute to our module.

Finally we'll add our module to Packagist, so it can be installed in many SilverStripe sites.

We've got a lot of exciting, new stuff to cover. So let's get to it!

## Adding/improving tests

There is a lot of information out there, on testing. So it's important that we better define what we want to focus on. You can think of tests as a secondary codebase which ensures our primary codebase (or in this case the module we're building) works correctly.

We don't technically need tests to make a module, in much the same way as one doesn't technically need a script to make a movie. It's just a really good idea to have a script. Similarly, it's a good idea to have tests so we know our module is doing exactly what it should be doing.

Some people like to write tests before they write any other code. This is often called Test-Driven Development (or TDD for short). It's an interesting way to build software, and one I highly recommend you try.

We've already got a module to work with, so we're adding the tests after. Still, having tests (whether we made them before or after the rest of our code) is still better than having no tests. 

### How many tests do we need?

So how many tests do we need? This is an interesting question because the answer is; "well it depends". We write tests because we want to know our module works. How many tests we write depends on how many it takes to ensure our code does what it needs to do, well.

The number of tests is less important than the amount of code they test. After all, I can write 100 tests which check small variations of the same code, but they'll start to decrease in value. 

No - what we want to do is cover the important parts of our code in enough tests to make sure our code does what it needs. This is referred to as Test Coverage (or the percentage of code which has any corresponding tests).

### What kinds of tests are there?

It can be confusing, when first learning about testing, to hear about all the different types of tests it is possible to write. Testing is full of jargon, so it's again helpful for us to decide what kinds of tests we want to write:

#### Unit tests

Unit tests are the smallest, and often the most complicated, tests we can write. Like their name suggests, we write unit tests to ensure individual units of code work as expected. 

Given a class of 4 public methods, we'll write at least 1 unit test for each method, to assert that each method does exactly what is needs to with any input.

As a side-note: did you notice the structure of my last statement? Given some pre-conditions, when something happens we assert an outcome. That's an important structure: we'll see again and again.

Unit tests are meant to be very small in scope, checking the output of a single method at a time. The less code being tested by a single unit test, the better.

This is what makes them so complicated. We sometimes have to take steps to ensure that we're only testing a single method. Usually these steps take the form of replacing real objects with fake objects. 

This is where it becomes important for our methods not to have side-effects or multiple responsibilities. When our methods have side-effects then out tests need to account for changes outside of a single method. When our methods have multiple responsibilities then our test balloon out of proportion.

#### Functional tests

Functional tests are a little more down-to-earth, in the sense that they allow interaction between many objects. With functional tests, we're no longer trying to test a single method but rather a small slice of the whole system.

To illustrate the difference: a unit test might only test that image-manipulation functions are called by a gallery class' render function, but a functional test might compare a resized  gallery image to a set of expected images.

In fact, this kind of "set of expected images" is called a fixture, and is often an easy way to distinguish functional tests from unit tests.

You see, functional tests forgo using the fake objects that unit tests do, by using real objects. Functional tests focus on the interactions of multiple processes or methods; testing real-world inputs and real-world outputs.

#### Acceptance tests

Acceptance tests are a high-level overview of the functionality of a module or application. In PHP, these often take the form of; "given a URL, when I click these things then  something intended happens". 

Acceptance tests are similar to functional tests in that they test a slice of the whole application. But where functional tests are of the interactions of multiple objects or methods: acceptance tests are to assert that the system as a whole fulfils a requirement.

As a result, acceptance tests often resemble user-stories. They're the answer to the question; "does this part of my module or application do what I intended it to" without the gritty implementation details getting in the way.

### What tests should I write?

SilverStripe modules usually have functional tests. This is often the case with add-ons to frameworks, as they'll depend on some framework functionality. 

It's often too difficult to fake every part of the framework, in order to test a single method. Side-effects and interactions are prevalent, especially when dealing with modules that add functionality to a pre-constructed CMS interface.

Functional testing allows us to insert database records, trap emails that have been sent or even simulate browser requests. It can be slightly harder to narrow down the location of bugs, than with unit testing, but it is easier to detect the presence of bugs between objects.

Acceptance tests are also common, especially with modules that add visible features to the CMS. It's easier to understand and write tests that replicate how we would normally interact with a system. "When I go to my profile, and click the edit button, I am presented with a form" is understandable because it's an expression of what we might actually do in a browser.

Given these three types of tests, we're going to focus on functional tests. It's possible to write all three kinds, in a SilverStripe project, but I think functional tests will give us the most value in the shortest amount of time.

## Connecting to CI services

Continuous Integration (or CI for short) is what we call web services which continuously monitor our code and applications. There are many of these kinds of services, but we're going to focus on two: Travis and Scrutinizer.

Travis is a testing service. When we connect it to our Github repositories, it will test the code that we commit to them. If there are errors, we can see this by adding a badge to our readme.

Similarly, Scrutninizer checks our repository every time we commit code to it; but what it's checking is code quality. There are a number of metrics it can apply to guess if our code is readable, free of errors and extendable.

### Configuring Travis

We tell Travis how to test our applications, but creating a file called `.travis.yml`. In this file we can list things like the versions of PHP we want to test our application against, and the environment variables it should set beforehand. These environment variables can reflect difference versions of SilverStripe to test against or different database providers to test against.

If our tests need special dependencies installed beforehand, this is the best place to define how those are loaded before the tests are run. The Travis file supports different kinds of events, like `before_script` or `after_success`. Not only can we change the system before, but we can also do things depending on whether the tests passed or failed...

### Connecting Travis

Once we've got that config ready to go, it's time to plug the module into Travis. Create an account and log into Travis. You can connect with your Github account, so there should be little to no setup required for this.

Go to the "Accounts" section and click "Sync". If you can't see the organisation the module is in; you probably have to request access to it by clicking on the "Renew and add" link on the bottom left.

Find the organisation where the module is, and click "Grant access". Another "Sync" should do it. Enable the module repository and Travis should start watching for changes.

### Configuring Scrutinizer

We configure Scrutinizer in the same way. First we create a file called `.scrutinizer.yml`. Then we tell Scrutinizer what language our module is in. Scrutinizer supports multiple languages, including Python and Ruby, which is helpful to remember if we're ever coding in those and need some quality control...

We add instructions for which checks to run. Overall there are fewer things to define here than in Travis' config file, so it shouldn't take all that long.

### Connecting Scrutinizer

Connecting Scrutinizer is just as easy as Travis. Create an account and log in. You can also use a Github account for this. Then click "Add repository". Then add the user/repo part of Github URL and pick PHP from the list of languages.

Don't worry about running the tests here. We could but it's better for us to run them just with Travis because we can do more there.

Click "Add Repository" and we're done here. We'll keep these tabs open to see when the tests and inspections are run...

## Adding/improving docs

As we change and improve our module, we're going to want to keep the docs up to date. If you don't have any docs, now is a good time to make some.

Docs are an excellent way for other developers (and even users) to see what your module offers. Perhaps your module adds some CMS fields, or a new front-end section. The one we're building here adds a new field to the CMS, so we could use docs for developers and CMS users alike.

Docs are best kept in `docs/en`. You can structure them any way you like, but I find it best to begin with `index.md`, `introduction.md` or `getting-started.md`. Something like that is a good way to point readers to the place they will start with the documentation. The `.md` part is short for Markdown, which is an almost-plain-text language with support for some formatting elements, like headings and lists.

You may also have heard of Github-flavoured Markdown (or GFM for short) which is a superset of Markdown, supporting code blocks and other useful formatting elements.

When it comes to user documentation, it's best to put this in a `user-guide.md` file, or a folder of Markdown files called `user-guide`. That makes it obvious which parts of the documentation are for developers (or general consumption) and which parts are specifically for CMS users. It's also how we load this kind of documentation into sites like <userhelp.silverstripe.org> and <docs.silverstripe.org>.

Let's introduce our module with a small code snippet, and screenshot. It's ok if you don't have one of these things. This is a good place to point out things like a contribution guide, code of conduct, license or even SemVer compliance. 

Be sure to include as many images and code snippets as possible, so there are few unanswered questions about how to use your module. You can also include your name or Twitter handle for people to ask their questions on those platforms.

Once you're done, commit and push those changes to Github. Now is a good time to see if Travis and Scrutinizer are automatically checking the repository.

## Formatting code

Let's move on to formatting our code. If you haven't already picked a code style guide for your work, may I suggest PSR-2? It's the recommended code style for SilverStripe Framework, CMS, and Supported Modules.

It covers things like how to format whitespace and where to put braces. You can read up on it at <php-fig.org/psr/psr-2>. 

Now, you don't have to remember all these rules when you're writing code. You'll gradually learn them, over time. For now, you can use an automated tool to re-format your code for you. It's called `php-cs-fixer` and you can download it through Composer...

`php-cs-fixer` supports a number of different code styles, but  the one we're interested in is PSR-2. You can use it to transform your source files, and even check before you do with a dry-run.

Try to keep commits where you format your code apart from commits where you add features and/or fix bugs. Mixing the two can make it harder for collaborators to understand the changes you've made, and often leads to longer review periods.

Remember also that formatting shouldn't affect the behaviour of your code. You shouldn't need to bump the version number of your module just because you've applied some formatting...

## Adding community files

We're almost there! Now is a good time to add a few community files. You may have hinted at these in your docs or "readme" file. 

I call them community files because they don't really help you personally, but they are a great help to other developers wanting to know how to use and/or contribute to your module.

When I'm adding these files to my projects, I like to add separate contributing, change log, code of conduct, and license files. I also add common configuration files like `.gitattributes`, `.gitignore` and `.editorconfig`.

### Which license should I choose?

It can be tricky knowing which license to choose for your project. What do they all mean? Will you get in trouble if you choose the wrong one?

#### A few common licenses

- MIT
- BSD
- GPL

MIT and BSD are permissive licenses. They allow modification and distribution. You can use code released under these to build whatever you like, and sell it if you so desire.

SilverStripe Framework and CMS are released under BSD, as are many of the community modules. 

On the other hand, GPL is a copyleft license, which basically means if you use GPL code in your module or project, that module or project also needs to be GPL. It's meant to keep code free.

We feel BSD works well for us, so you might want to try it yourself. Whatever license you choose, you still own your code. But unless you have a clear license, nobody else is really allowed to use your code...

You can learn more about these licenses (and others) at <https://opensource.org/licenses>.

You might also want to add a Contributor License Agreement (or CLA for short) which tells contributors how their contributions will be re-licensed as part of regular releases of your module. we have one for SilverStripe, if you want to see an example: <https://docs.silverstripe.org/en/4/contributing/code/#contributing-code-submitting-bugfixes-and-enhancements>.

Remember to tag a new release and make sure it is available on Packagist (like we learned about in the last lesson).