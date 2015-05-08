from django.shortcuts import render


def home(request):
    return render(request, 'home.html', {})

def foobar_Blah(request):
    something = 1
    anotherThing_e = 2
    andAnother = 4
    return render(request, 'home.html', {})
