from torch import nn


class MLP(nn.Module):
    def __init__(self, nin, nout, nh, n_layers=3, dropout=0):
        super().__init__()
        layers = []
        for i in range(n_layers):
            layers.append(nn.Linear(nin, nh))
            if dropout > 0:
                layers.append(nn.Dropout(dropout))
            layers.append(nn.LeakyReLU(0.2))
            nin = nh
        final_layer = nn.Linear(nh, nout)
        self.reset_parameters(final_layer)
        layers.append(final_layer)
        self.net = nn.Sequential(*layers)

    def reset_parameters(self, module):
        init_range = 0.07
        module.weight.data.uniform_(-init_range, init_range)
        module.bias.data.zero_()

    def forward(self, x):
        return self.net(x)