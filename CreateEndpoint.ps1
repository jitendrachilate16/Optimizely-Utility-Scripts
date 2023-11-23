$apiName = Read-Host "Enter the API Name"
if ($apiName -eq "") {
    Write-Host "You did not enter the API Name!"
    exit
}

$apiPath = Read-Host "Enter the API Path"
if ($apiPath -eq "") {
    Write-Host "You did not enter the API Path!"
    exit
}


#Handlers
$handlerFolder = $apiPath+"\Handlers"
if (!(Test-Path -Path $handlerFolder -PathType Container)){ New-Item -Path $handlerFolder -ItemType Directory }
$handlerNamespace = $handlerFolder -split [regex]::Escape("src\")
$handlerNamespace = $handlerNamespace[1] -replace [regex]::Escape("\"), "."
$handlerNamespace = $handlerNamespace -replace [regex]::Escape(".."), "."
$handlerFolder = $handlerFolder + "\" + $apiName+"Handler.cs"
$serviceNamespace = $handlerNamespace -replace [regex]::Escape("Handler"), "Services.Parameter"
$resultNamespace = $handlerNamespace -replace [regex]::Escape("Handler"), "Services.Result"
$handlerName = $apiName + "Handler"
$serviceParameter = $apiName + "ServiceParameter"
$serviceResult = $apiName + "Result"
$csHandlerContent = @"
using Insite.Core.Interfaces.Dependency;
using Insite.Core.Services.Handlers;
using Insite.Core.Interfaces.Data;
using System;
using $serviceNamespace;
using $resultNamespace;

namespace $handlerNamespace
{

    [DependencyName("$apiName")]
    public sealed class $handlerName
    : HandlerBase<$serviceParameter, $serviceResult>
    {
        public override int Order => 100;
        
        public override $serviceResult Execute(IUnitOfWork unitOfWork, $serviceParameter parameter, $serviceResult result)
        {
            result.SampleProperty = "This the sample proerpty!";
            return this.NextHandler.Execute(unitOfWork, parameter, result);
        }

    }
}
"@

#ApiModels
$apiModelsFolder = $apiPath+"\ApiModels"
if (!(Test-Path -Path $apiModelsFolder -PathType Container)){ New-Item -Path $apiModelsFolder -ItemType Directory }
$apiModelsNamespace = $apiModelsFolder -split [regex]::Escape("src\")
$apiModelsNamespace = $apiModelsNamespace[1] -replace [regex]::Escape("\"), "."
$apiModelsNamespace = $apiModelsNamespace -replace [regex]::Escape(".."), "."
$apiModelsFolderModel = $apiModelsFolder + "\" + $apiName+"Model.cs"
$apiModelsFolderParameter = $apiModelsFolder + "\" + $apiName+"Parameter.cs"
$apiModelName = $apiName + "Model"
$lApiModelName = $apiModelName.Substring(0, 1).ToLower() + $apiModelName.Substring(1)
$apiParameterName = $apiName + "Parameter"
$lApiParameterName = $apiParameterName.Substring(0, 1).ToLower() + $apiParameterName.Substring(1)

$modelContent = @"
using Insite.Core.Plugins.Search.Dtos;
using Insite.Core.WebApi;
using Newtonsoft.Json;
using System.Collections.Generic;

namespace $apiModelsNamespace
{

    public class $apiModelName : BaseModel
        
    {
        [JsonProperty(DefaultValueHandling = DefaultValueHandling.Ignore)]
        public PaginationModel Pagination { get; set; }

        [JsonProperty(DefaultValueHandling = DefaultValueHandling.Ignore)]
        public string SampleProperty { get; set; }
       
    }
}
"@

$parameterContent = @"
using Insite.Core.WebApi;
using System;
using System.Collections.Generic;

namespace $apiModelsNamespace
{

    public class $apiParameterName : BaseParameter
        
    {
        public string SampleProperty { get; set; }
        public int? Page { get; internal set; }
    }
}
"@

#Services
$servicesFolder = $apiPath+"\Services"
if (!(Test-Path -Path $servicesFolder -PathType Container)){ New-Item -Path $servicesFolder -ItemType Directory }
$servicesNamespace = $servicesFolder -split [regex]::Escape("src\")
$servicesNamespace = $servicesNamespace[1] -replace [regex]::Escape("\"), "."
$servicesNamespace = $servicesNamespace -replace [regex]::Escape(".."), "."
$servicesFolderClass = $servicesFolder + "\" + $apiName+"Service.cs"
$servicesFolderInterface = $servicesFolder + "\I" + $apiName+"Service.cs"
$serviceName = $apiName + "Service"
$iServiceName = "I" + $serviceName
$serviceResultName = $apiName + "Result"
$serviceMethodName = "Get" + $apiName + "Collection"
$servicesParameterName = $apiName + "ServiceParameter"

$servicesParameterFolder = $apiPath+"\Services\Parameters"
if (!(Test-Path -Path $servicesParameterFolder -PathType Container)){ New-Item -Path $servicesParameterFolder -ItemType Directory }
$servicesParametersNamespace = $servicesParameterFolder -split [regex]::Escape("src\")
$servicesParametersNamespace = $servicesParametersNamespace[1] -replace [regex]::Escape("\"), "."
$servicesParametersNamespace = $servicesParametersNamespace -replace [regex]::Escape(".."), "."
$servicesParameterFolder = $servicesParameterFolder + "\" + $apiName+"ServiceParameter.cs"

$servicesResultFolder = $apiPath+"\Services\Results"
if (!(Test-Path -Path $servicesResultFolder -PathType Container)){ New-Item -Path $servicesResultFolder -ItemType Directory }
$servicesResultNamespace = $servicesResultFolder -split [regex]::Escape("src\")
$servicesResultNamespace = $servicesResultNamespace[1] -replace [regex]::Escape("\"), "."
$servicesResultNamespace = $servicesResultNamespace -replace [regex]::Escape(".."), "."
$servicesResultFolder = $servicesResultFolder + "\" + $apiName+"Result.cs"



$iServiceContent = @"
using Insite.Core.Interfaces.Dependency;
using Insite.Core.Services;
using $servicesResultNamespace;
using $servicesParametersNamespace;

namespace $servicesNamespace
{

    [DependencyInterceptable]
    public interface $iServiceName :
        IDependency, 
        ISettingsService
    {
       $serviceResultName $serviceMethodName($servicesParameterName parameter);
    }
}
"@

$serviceContent = @"
using Insite.Core.Interfaces.Data;
using Insite.Core.Interfaces.Dependency;
using Insite.Core.Services;
using Insite.Core.Services.Handlers;
using $resultNamespace;
using System;
using $servicesParametersNamespace;

namespace $servicesNamespace
{

    public class $serviceName :
        ServiceBase,
        $iServiceName,
        IDependency, 
        ISettingsService
    {
        protected readonly IHandlerFactory HandlerFactory;

        public $serviceName(IUnitOfWorkFactory unitOfWorkFactory, IHandlerFactory handlerFactory)
      : base(unitOfWorkFactory)
        {
            this.HandlerFactory = handlerFactory;
        }

         [Transaction]
        public $serviceResultName $serviceMethodName($servicesParameterName parameter)
        {
            $serviceResultName result = ($serviceResultName)null;
            this.UnitOfWork.ExecuteWithoutChangeTracking((Action)(() => result = this.HandlerFactory.GetHandler<IHandler<$servicesParameterName, $serviceResultName>>().Execute(this.UnitOfWork, parameter, new $serviceResultName())));
            return result;
        }
       
    }
}
"@

#Services/Parameters
$serviceParameterContent = @"
using Insite.Core.Context;
using Insite.Core.Extensions;
using Insite.Core.Interfaces.EnumTypes;
using Insite.Core.Plugins.Pricing;
using System;
using System.Collections.Generic;
using System.Linq;
using $apiModelsNamespace;
using Insite.Core.WebApi;
using Insite.Core.Services;

namespace $servicesParametersNamespace
{

    public class $servicesParameterName : PagingParameterBase
        
    {
       public $servicesParameterName(
          $apiParameterName $lApiParameterName)
        {
            if ($lApiParameterName == null)
                return;
            this.SampleProperty = $lApiParameterName.SampleProperty;
        }

        public string SampleProperty { get; set; }
    }
}
"@

#Services/Result
$lServiceResultName = $serviceResultName.Substring(0, 1).ToLower() + $serviceResultName.Substring(1)
$serviceResultContent = @"
using Insite.Core.Plugins.Search.Dtos;
using Insite.Core.Services;
using Insite.Data.Entities;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;

namespace $servicesResultNamespace
{

    public class $serviceResultName : PagingResultBase
        
    {
        public virtual string SampleProperty { get; set; }
        public virtual ReadOnlyCollection<SortOrderDto> SortOptions { get; set; }
        public virtual string SortOrder { get; set; }
        public virtual bool ExactMatch { get; set; }
    }
}
"@



#Mappers
$mapperFolder = $apiPath+"\Mappers"
if (!(Test-Path -Path $mapperFolder -PathType Container)){ New-Item -Path $mapperFolder -ItemType Directory }
$mappersNamespace = $mapperFolder -split [regex]::Escape("src\")
$mappersNamespace = $mappersNamespace[1] -replace [regex]::Escape("\"), "."
$mappersNamespace = $mappersNamespace -replace [regex]::Escape(".."), "."

$mapperFolderClass = $mapperFolder + "\" + $apiName+"Mapper.cs"
$mapperFolderInterface = $mapperFolder + "\I" + $apiName+"Mapper.cs"

$mapperName = $apiName + "Mapper"
$imapperName = "I" + $mapperName

$iMapperContent = @"
using Insite.Core.Interfaces.Dependency;
using Insite.Core.WebApi.Interfaces;
using $apiModelsNamespace;
using $servicesNamespace;
using $servicesResultNamespace;
using $servicesParametersNamespace;

namespace $mappersNamespace
{

    [DependencyInterceptable]
    public interface $imapperName :
        IWebApiMapper<$apiParameterName, $servicesParameterName, $serviceResultName, $apiModelName>,
        IDependency, 
        IExtension
    {
       
    }
}
"@


$mapperContent = @"
using Insite.Core.Interfaces.Dependency;
using Insite.Core.Plugins.Search.Dtos;
using Insite.Core.Plugins.Utilities;
using Insite.Core.Services;
using Insite.Core.WebApi;
using Insite.Core.WebApi.Interfaces;
using Insite.Core.Extensions;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net.Http;
using $apiModelsNamespace;
using $servicesNamespace;
using $servicesResultNamespace;
using $servicesParametersNamespace;

namespace $mappersNamespace
{

    public class $mapperName : 
    $imapperName,
    IWebApiMapper<$apiParameterName, $servicesParameterName, $serviceResultName, $apiModelName>,
    IDependency,
    IExtension
    {
        public $mapperName(
        IUrlHelper urlHelper,
        IObjectToObjectMapper objectToObjectMapper)
        {
        }

        public $servicesParameterName MapParameter($apiParameterName apiParameter, HttpRequestMessage request)
        {
            $servicesParameterName parameter = new $servicesParameterName(apiParameter);
            if (apiParameter != null)
                parameter.Page = new int?(apiParameter.Page ?? 1);
            string queryString = request.GetQueryString("filter");
            if (!queryString.IsBlank())
            {
                string[] source2 = queryString.ToLower().Split(',');
                parameter.PageSize = ((IEnumerable<string>)source2).Contains<string>("pagesize")?20:10;
            }
            return parameter;
        }

        public $apiModelName MapResult($serviceResultName serviceResult, HttpRequestMessage request)
        {
            $apiModelName $lApiModelName = new $apiModelName();
            if (serviceResult != null)
            {
                $lApiModelName.SampleProperty = serviceResult.SampleProperty;
                $lApiModelName.Pagination = this.MakePaging(request, serviceResult);
            }
            return $lApiModelName;
        }

        public virtual PaginationModel MakePaging(
          HttpRequestMessage httpRequestMessage,
          $serviceResultName $lServiceResultName)
        {
            PaginationModel paginationModel = new PaginationModel((PagingResultBase)$lServiceResultName);
            if (paginationModel.NumberOfPages > 1 && paginationModel.Page < paginationModel.NumberOfPages)
            {
                var routeValues = new
                {
                    page = paginationModel.Page + 1,
                    query = httpRequestMessage.GetQueryString("query"),
                    pageSize = httpRequestMessage.GetQueryString("pageSize"),
                    categoryId = httpRequestMessage.GetQueryString("categoryId"),
                    sort = httpRequestMessage.GetQueryString("sort"),
                    expand = httpRequestMessage.GetQueryString("expand")
                };
            }
            if (paginationModel.Page > 1)
            {
                var routeValues = new
                {
                    page = paginationModel.Page - 1,
                    query = httpRequestMessage.GetQueryString("query"),
                    pageSize = paginationModel.PageSize,
                    categoryId = httpRequestMessage.GetQueryString("categoryId"),
                    sort = httpRequestMessage.GetQueryString("sort"),
                    expand = httpRequestMessage.GetQueryString("expand")
                };
            }
            if ($lServiceResultName.SortOptions != null)
            {
                paginationModel.SortOptions = $lServiceResultName.SortOptions.Select<SortOrderDto, SortOptionModel>((Func<SortOrderDto, SortOptionModel>)(o => new SortOptionModel()
                {
                    DisplayName = o.DisplayName,
                    SortType = o.SortType
                })).ToList<SortOptionModel>();
                paginationModel.SortType = $lServiceResultName.SortOrder;
            }
            return paginationModel;
        }
            
    }
}
"@

#Controllers
$controllerFolder = $apiPath+"\Controller"
if (!(Test-Path -Path $controllerFolder -PathType Container)){ New-Item -Path $controllerFolder -ItemType Directory }
$controllerNamespace = $controllerFolder -split [regex]::Escape("src\")
$controllerNamespace = $controllerNamespace[1] -replace [regex]::Escape("\"), "."
$controllerNamespace = $controllerNamespace -replace [regex]::Escape(".."), "."
$controllerFolder = $controllerFolder + "\" + $apiName+"V1Controller.cs"
$controllerName = $apiName + "Controller"
$lControllerName = $controllerName.Substring(0, 1).ToLower() + $controllerName.Substring(1)
$lMapperName = $mapperName.Substring(0, 1).ToLower() + $mapperName.Substring(1)
$lserviceName = $serviceName.Substring(0, 1).ToLower() + $serviceName.Substring(1)
$routeName = $apiName + "V1"
$csControllerContent = @"
using Insite.Core.Plugins.Utilities;
using Insite.Core.WebApi;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using $servicesNamespace;
using $mappersNamespace;
using $apiModelsNamespace;
using $servicesResultNamespace;
using $servicesParametersNamespace;
using System;

namespace $controllerNamespace
{

    [RoutePrefix("api/v1/$apiName")]
    public class $controllerName : BaseApiController
    {
        private readonly $imapperName $lMapperName;
        private readonly $iserviceName $lServiceName;

        public $controllerName(ICookieManager cookieManager,
        $imapperName $lMapperName,
        $iserviceName $lServiceName)
        : base(cookieManager)
        {
            this.$lMapperName = $lMapperName;
            this.$lServiceName = $lServiceName;
        }

       
        [Route("", Name = "$routeName")]
        [ResponseType(typeof($apiModelName))]
        public async Task<IHttpActionResult> Get([FromUri] $apiParameterName model)
        {
            $controllerName $lControllerName = this;
            return await $lControllerName.ExecuteAsync<$imapperName,
                $apiParameterName,
                $servicesParameterName,
                $serviceResultName,
                $apiModelName>($lControllerName.$lMapperName,
                new Func<$servicesParameterName, $serviceResultName>
                ($lControllerName.$lServiceName.$serviceMethodName),
                model);
        }

    }
}
"@


$csControllerContent | Set-Content -Path $controllerFolder
$csHandlerContent | Set-Content -Path $handlerFolder
$modelContent | Set-Content -Path $apiModelsFolderModel
$parameterContent | Set-Content -Path $apiModelsFolderParameter
$iServiceContent | Set-Content -Path $servicesFolderInterface
$serviceContent | Set-Content -Path $servicesFolderClass
$serviceParameterContent | Set-Content -Path $servicesParameterFolder
$serviceResultContent | Set-Content -Path $servicesResultFolder
$iMapperContent | Set-Content -Path $mapperFolderInterface
$mapperContent | Set-Content -Path $mapperFolderClass