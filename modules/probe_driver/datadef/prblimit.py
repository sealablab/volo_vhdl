from dataclasses import dataclass
from typing import Annotated
import numpy as np

@dataclass
class TriggerConfig:
    trigger_in_threshold: float
    trigger_in_duration_min: int   # in clk cycles
    trigger_in_duration_max: int   # in clk cycles
    intensity_in_min: Annotated[int, np.uint16]
    intensity_in_max: Annotated[int, np.uint16]
