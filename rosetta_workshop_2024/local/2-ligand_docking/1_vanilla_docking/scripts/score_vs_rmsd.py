#! /usr/bin/python

import matplotlib.pyplot as plt
import numpy as np
#%matplotlib inline
from sys import argv
import subprocess
import pandas as pd

#subprocess.call (command, shell=True)


input_file = argv[1]
output_file = argv[2]


x,y = np.loadtxt(argv[1], delimiter=',', usecols=(3,2), unpack=True)
plt.figure(figsize=(7,5),dpi=400)
plt.style.use('ggplot')
# axis can be limited on some values with the line below.
plt.xlabel('RMSD ($A^0$)')
plt.ylabel('Rosetta Energy (REU)')
plt.scatter(x, y, color = 'b', edgecolors='k', linewidths=1)
plt.axvline(x=2, color='k', linewidth=0.5, linestyle='-.')
plt.xlim(0,10)
plt.ylim(ymax=0)
plt.legend(title=argv[2])
plt.savefig(argv[2]+".png")
#plt.show()             
