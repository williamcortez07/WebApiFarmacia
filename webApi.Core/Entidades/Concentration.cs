using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class Concentration
    {
        public int ConcentrationId { get; set; }
        public string Volume {  get; set; }
        public string Porcentage { get; set; }
        public bool IsAtive { get; set; }

    }
}
