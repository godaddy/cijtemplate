from django.shortcuts import render


def home(request):
    return render(request, 'home.html', {})

def aReally_BadMethodNameThat_iswaytoolongforthisthing(request):
    asdf = 123
    dfg = 345
    dfg =567
    poi = 345
    return None
