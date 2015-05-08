from django.shortcuts import render


def home(request):
    return render(request, 'home.html', {})

def aBad_FUnctionname(request):
    asdf = 123
    asdf = 345
    sdfffdfs = 345435
    return None
